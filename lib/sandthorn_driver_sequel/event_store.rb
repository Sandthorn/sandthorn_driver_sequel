require "sandthorn_driver_sequel/access/aggregate_access"
require "sandthorn_driver_sequel/access/event_access"
require "sandthorn_driver_sequel/access/snapshot_access"
require "sandthorn_driver_sequel/storage"

module SandthornDriverSequel
  class EventStore
    include EventStoreContext

    attr_reader :driver, :context

    def initialize connection, configuration, context = nil
      @driver = connection
      @context = context
      @event_serializer = configuration.event_serializer
      @event_deserializer = configuration.event_deserializer
      @snapshot_serializer = configuration.snapshot_serializer
      @snapshot_deserializer = configuration.snapshot_deserializer
    end

    def self.from_url url, configuration, context = nil
      new(SequelDriver.new(url: url), configuration, context)
    end

    #save methods
    def save_events events, aggregate_id, class_name
      driver.execute_in_transaction do |db|
        aggregates = get_aggregate_access(db)
        event_access = get_event_access(db)
        aggregate = aggregates.find_or_register(aggregate_id, class_name)
        event_access.store_events(aggregate, events)
      end
    end

    def save_snapshot aggregate
      driver.execute_in_transaction do |db|
        snapshot_access = get_snapshot_access(db)
        snapshot_access.record_snapshot(aggregate)
      end
    end

    #get methods
    def all aggregate_type
      return get_aggregate_ids(aggregate_type: aggregate_type).map do |id|
        get_aggregate_events_from_snapshot(id)
      end
    end

    def find aggregate_id, aggregate_type
      get_aggregate_events_from_snapshot(aggregate_id)
    end

    
    def get_aggregate_events(aggregate_id)
      driver.execute do |db|
        events = get_event_access(db)
        events.find_events_by_aggregate_id(aggregate_id)
      end
    end

    # If the aggregate has a snapshot, return events starting from the snapshots.
    # Otherwise, return all events.
    # TODO: needs a better name
    def get_aggregate_events_from_snapshot(aggregate_id)
      driver.execute do |db|
        snapshots = get_snapshot_access(db)
        event_access = get_event_access(db)
        snapshot = snapshots.find_by_aggregate_id(aggregate_id)
        if snapshot
          events = event_access.after_snapshot(snapshot)
          snapshot_event = build_snapshot_event(snapshot)
          events.unshift(snapshot_event)
        else
          event_access.find_events_by_aggregate_id(aggregate_id)
        end
      end
    end



    

    def get_aggregate aggregate_id, *class_name
      warn(":get_aggregate is deprecated. Use :get_aggregate_events_from_snapshot")
      get_aggregate_events_from_snapshot(aggregate_id)
    end

    

    def get_aggregate_ids(aggregate_type: nil)
      driver.execute do |db|
        access = get_aggregate_access(db)
        access.aggregate_ids(aggregate_type: aggregate_type)
      end
    end

    def get_aggregate_list_by_typename(type)
      warn(":get_aggregate_list_by_typenames is deprecated. Use :get_aggregate_ids")
      get_aggregate_ids(aggregate_type: type)
    end

    def get_all_types
      driver.execute do |db|
        access = get_aggregate_access(db)
        access.aggregate_types
      end
    end

    def get_snapshot aggregate_id
      driver.execute do |db|
        snapshots = get_snapshot_access(db)
        snapshot = snapshots.find_by_aggregate_id(aggregate_id)
        snapshot.data
      end
    end

    def get_events(*args)
      driver.execute do |db|
        event_access = get_event_access(db)
        event_access.get_events(*args)
      end
    end

    def get_new_events_after_event_id_matching_classname event_id, class_name, take: 0
      get_events(after_sequence_number: event_id, aggregate_types: Utilities.array_wrap(class_name), take: take)
    end

    private

    def build_snapshot_event(snapshot)
      {
        aggregate: snapshot.data,
      }
    end

    def transform_snapshot(snapshot)
      {
          aggregate_version: snapshot.aggregate_version,
          event_data: snapshot.snapshot_data
      }
    end

    def get_aggregate_access(db)
      @aggregate_access ||= AggregateAccess.new(storage(db))
    end

    def get_event_access(db)
      @event_access ||= EventAccess.new(storage(db), @event_serializer, @event_deserializer)
    end

    def get_snapshot_access(db)
      @snapshot_access ||= SnapshotAccess.new(storage(db), @snapshot_serializer, @snapshot_deserializer)
    end

    def storage(db)
      @storage ||= Storage.new(db, @context)
    end

  end
end