require 'sandthorn_driver_sequel/sequel_driver'

module SandthornDriverSequel
  class EventStore
    include EventStoreContext
    attr_reader :driver, :context, :url
    def initialize url: nil, context: nil
      @driver = SequelDriver.new url: url
      @context = context
      @url = url
    end

    def save_events aggregate_events, originating_aggregate_version, aggregate_id, *class_name
      current_aggregate_version = originating_aggregate_version
      aggregate_type = class_name.first.to_s
      driver.execute_in_transaction do |db|
        if current_aggregate_version == 0
          to_insert = {aggregate_id: aggregate_id, aggregate_type: aggregate_type, aggregate_version: 0}
          pk_id = db[aggregates_table_name].insert(to_insert)
        else
          current_aggregate = get_current_aggregate_from_aggregates_table aggregate_id, aggregate_type, db
          pk_id = current_aggregate[:id]
          if current_aggregate[:aggregate_version] != current_aggregate_version
            error_message = "#{aggregate_type} with id #{aggregate_id} should be att version #{current_aggregate_version} but was #{current_aggregate[:aggregate_version]} in the event store."
            raise SandthornDriverSequel::Errors::WrongAggregateVersionError.new(error_message)
          end
        end
        timestamp = Time.now.utc
        aggregate_events.each do |event|
          current_aggregate_version += 1
          if current_aggregate_version != event[:aggregate_version]
            error_message = "#{aggregate_type} with id #{aggregate_id}: expected event with version #{current_aggregate_version}, but got #{event[:aggregate_version]}"
            raise SandthornDriverSequel::Errors::ConcurrencyError.new(error_message)
          end
          to_insert = ({aggregate_table_id: pk_id, aggregate_version: event[:aggregate_version], event_name: event[:event_name], event_data: event[:event_data], timestamp: timestamp})
          db[events_table_name].insert(to_insert)
        end
        db[aggregates_table_name].where(id: pk_id).update(aggregate_version: current_aggregate_version)
      end
    end

    def save_snapshot aggregate_snapshot, aggregate_id, class_name
      #ar_snapshot.event_name = snapshot[:event_name]
      #ar_snapshot.event_data = snapshot[:event_data]
      #ar_snapshot.aggregate_version = snapshot[:aggregate_version]
      #ar_snapshot.aggregate_id = aggregate_id
      driver.execute_in_transaction do |db|
        current_aggregate = get_current_aggregate_from_aggregates_table aggregate_id, class_name, db
        pk_id = current_aggregate[:id]
        current_snapshot = get_current_snapshot pk_id, db
        aggregate_version = aggregate_snapshot[:aggregate_version]
        return if !current_snapshot.nil? && current_snapshot[:aggregate_version] == aggregate_version
        if current_aggregate[:aggregate_version] < aggregate_version
          error_message = "#{class_name} with id #{aggregate_id}: tried to save snapshot with version #{aggregate_version}, but current version is at #{current_aggregate[:aggregate_version]}"
          raise SandthornDriverSequel::Errors::WrongAggregateVersionError.new error_message
        end
        if current_snapshot.nil?
          to_insert = {aggregate_version: aggregate_version, snapshot_data: aggregate_snapshot[:event_data], aggregate_table_id: pk_id }
          db[snapshots_table_name].insert(to_insert)
        else
          to_update = {aggregate_version: aggregate_version, snapshot_data: aggregate_snapshot[:event_data] }
          db[snapshots_table_name].where(aggregate_table_id: pk_id).update(to_update)
        end
      end
    end

    def get_aggregate_events aggregate_id, *class_name
      #aggregate_type = class_name.to_s unless class_name.nil?
      return aggregate_events aggregate_id: aggregate_id
    end

    def get_aggregate aggregate_id, *class_name
      snapshot = get_snapshot aggregate_id, class_name
      after_aggregate_version = 0
      after_aggregate_version = snapshot[:aggregate_version] unless snapshot.nil?
      events = aggregate_events after_aggregate_version: after_aggregate_version, aggregate_id: aggregate_id
      unless snapshot.nil?
        snap_event = snapshot
        snap_event[:event_name] = "aggregate_set_from_snapshot"
        events = events.unshift(snap_event)
      end
      events
    end
    def get_aggregate_list_by_typename class_name
      aggregate_type = class_name.to_s
      driver.execute do |db|
        db[aggregates_table_name].where(aggregate_type: aggregate_type).select(:aggregate_id).map { |e| e[:aggregate_id] }
      end
    end

    def get_all_typenames
      driver.execute do |db|
        db[aggregates_table_name].select(:aggregate_type).distinct.order(:aggregate_type).map{|e| e[:aggregate_type]}
      end
    end

    def get_snapshot aggregate_id, *class_name
      aggregate_type = class_name.first.to_s
      driver.execute do |db|
        current_aggregate = get_current_aggregate_from_aggregates_table aggregate_id, aggregate_type, db
        snap = get_current_snapshot current_aggregate[:id], db
        return nil if snap.nil?
        return {aggregate_version: snap[:aggregate_version], event_data: snap[:snapshot_data]}
      end
    end

    def get_new_events_after_event_id_matching_classname event_id, class_name, args = {}
      take = args.fetch(:take, 0)
      aggregate_type = class_name.to_s
      driver.execute do |db|
        query = db[events_table_name].join(aggregates_table_name, id: :aggregate_table_id, aggregate_type: aggregate_type)
        query = query.where{sequence_number > event_id}
        rel = "#{events_table_name}__aggregate_version".to_sym
        query = query.select(:aggregate_type, rel, :aggregate_id, :sequence_number, :event_name, :event_data, :timestamp)
        query = query.limit(take) if take > 0
        return query.order(:sequence_number).all
      end
    end
    def get_events aggregate_types: [], take: 0, after_sequence_number: 0, include_events: [], exclude_events: []
      include_events = include_events.map { |e| e.to_s  }
      exclude_events = exclude_events.map { |e| e.to_s  }
      aggregate_types = aggregate_types.map { |e| e.to_s  }
      driver.execute do |db|
        if aggregate_types.empty?
          query = db[events_table_name].join(aggregates_table_name, id: :aggregate_table_id)
        else
          query = db[events_table_name].join(aggregates_table_name, id: :aggregate_table_id, aggregate_type: aggregate_types)
        end
        query = query.where{sequence_number > after_sequence_number}
        unless include_events.empty?
          query = query.where(event_name: include_events)
        end
        unless exclude_events.empty?
          query = query.exclude(event_name: exclude_events)
        end
        rel = "#{events_table_name}__aggregate_version".to_sym
        query = query.select(:aggregate_type, rel, :aggregate_id, :sequence_number, :event_name, :event_data, :timestamp)
        query = query.limit(take) if take > 0
        return query.order(:sequence_number).all
      end
    end
    def obsolete_snapshots class_names: [], max_event_distance: 100
      driver.execute do |db|
        rel = "#{snapshots_table_name}__aggregate_version".to_sym
        aggr_rel = "#{aggregates_table_name}__aggregate_version".to_sym
        query_select = eval("lambda{(#{aggr_rel} - coalesce(#{rel},0)).as(distance)}")
        query = db[aggregates_table_name].left_outer_join(snapshots_table_name, aggregate_table_id: :id)
        query = query.select &query_select
        query = query.select_append(:aggregate_id, :aggregate_type)
        query_where = eval("lambda{(#{aggr_rel} - coalesce(#{rel},0)) > max_event_distance}")
        query = query.where &query_where 
        unless class_names.empty?
          class_names.map! {|c|c.to_s}
          query = query.where(aggregate_type: class_names)
        end
        query.all
      end
    end
    private

    def aggregate_events after_aggregate_version: 0, aggregate_id: nil
      
      rel = "#{events_table_name}__aggregate_version".to_sym
      where_proc = eval("lambda{ #{rel} > after_aggregate_version }")
      driver.execute do |db|
        query = db[events_table_name].join(aggregates_table_name, id: :aggregate_table_id, aggregate_id: aggregate_id)
        query = query.where &where_proc
        result = query.select(rel, :aggregate_id, :sequence_number, :event_name, :event_data, :timestamp).order(:sequence_number).all
      end
          
      # result = nil
      # Benchmark.bm do |x|
      #   x.report("find") { 
      #     rel = "#{events_table_name}__aggregate_version".to_sym
      #     where_proc = eval("lambda{ #{rel} > after_aggregate_version }")
      #     driver.execute do |db|
      #       query = db[events_table_name].join(aggregates_table_name, id: :aggregate_table_id, aggregate_id: aggregate_id)
      #       query = query.where &where_proc
      #       result = query.select(rel, :aggregate_id, :sequence_number, :event_name, :event_data, :timestamp).order(:sequence_number).all
      #     end
      #   }

      # end
      # result
    end
    def get_current_aggregate_from_aggregates_table aggregate_id, aggregate_type, db
      aggregate_type = aggregate_type.to_s
      current_aggregate = db[aggregates_table_name].where(aggregate_id: aggregate_id)
      if current_aggregate.empty?
        error_message = "#{aggregate_type} with id #{aggregate_id} was not found in the eventstore."
        raise SandthornDriverSequel::Errors::NoAggregateError.new(error_message)
      end
      current_aggregate.first
    end
    def get_current_snapshot aggregate_table_id, db
      snap = db[snapshots_table_name].where(aggregate_table_id: aggregate_table_id)
      return nil if snap.empty?
      snap.first
    end
  end
end
