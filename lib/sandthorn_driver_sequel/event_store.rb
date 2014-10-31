module SandthornDriverSequel
  class EventStore
    include EventStoreContext
    using Refinements::Array

    attr_reader :driver, :context, :url

    def initialize url: nil, context: nil
      @driver = SequelDriver.new url: url
      @context = context
      @url = url
    end

    def save_events events, aggregate_id, class_name
      driver.execute_in_transaction do |db|
        aggregates = get_aggregate_access(db)
        event_access = get_event_access(db)
        aggregate = aggregates.find_or_register(aggregate_id, class_name)
        event_access.store_events(aggregate, events)
      end
    end

    def get_aggregate_events(aggregate_id)
      driver.execute do |db|
        events = get_event_access(db)
        events.find_events_by_aggregate_id(aggregate_id)
      end
    end

    def save_snapshot aggregate_snapshot, aggregate_id
      driver.execute_in_transaction do |db|
        snapshot_access = get_snapshot_access(db)
        snapshot_access.record_snapshot(aggregate_id, aggregate_snapshot)
      end
    end

    def get_aggregate_events_from_snapshot(aggregate_id)
      driver.execute do |db|
        snapshots = get_snapshot_access(db)
        event_access = get_event_access(db)
        snapshot = snapshots.find_by_aggregate_id(aggregate_id)
        if snapshot
          events = event_access.after_snapshot(snapshot)
          snapshot_event = snapshot.values
          snapshot_event[:event_name] = "aggregate_set_from_snapshot"
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

    def get_aggregate_ids(type: nil)
      driver.execute do |db|
        access = get_aggregate_access(db)
        access.aggregate_ids(type: type)
      end
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
        transform_snapshot(snapshot)
      end
    end

    def get_events(*args)
      driver.execute do |db|
        event_access = get_event_access(db)
        event_access.get_events(*args)
      end
    end

    def get_new_events_after_event_id_matching_classname event_id, class_name, take: 0
      warn("get_new_events_after_event_id_matching_classname is deprecated")
      get_events(after_sequence_number: event_id, aggregate_types: Array.wrap(class_name), take: take)
    end

    def obsolete_snapshots(*args)
      driver.execute do |db|
        snapshots = get_snapshot_access(db)
        snapshots.obsolete(*args)
      end
    end

    private

    def transform_snapshot(snapshot)
      {
          aggregate_version: snapshot.aggregate_version,
          event_data: snapshot.snapshot_data
      }
    end

    def get_aggregate_access(db)
      AggregateAccess.new(storage(db))
    end

    def get_event_access(db)
      EventAccess.new(storage(db))
    end

    def get_snapshot_access(db)
      SnapshotAccess.new(storage(db))
    end

    def storage(db)
      Storage.new(db, context)
    end

  end
end