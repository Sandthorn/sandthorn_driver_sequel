module SandthornDriverSequel
  class NewEventStore
    include EventStoreContext

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
        event_access.store(aggregate, events)
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
          event_access.after_snapshot(snapshot)
        else
          event_access.find_events_by_aggregate_id(aggregate_id)
        end
      end
    end

    def get_aggregate aggregate_id, *class_name
      warn("This method is deprecated. Use :get_aggregate_events_from_snapshot")
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
        snapshots.find_by_aggregate_id(aggregate_id)
      end
    end
    def get_events aggregate_types: [], take: 0, after_sequence_number: 0, include_events: [], exclude_events: []; end
    def obsolete_snapshots class_names: [], max_event_distance: 100; end

    private

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
      storage = Storage.new(db, context)
    end


  end
end