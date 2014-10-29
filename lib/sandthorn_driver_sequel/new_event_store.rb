class NewEventStore
  include EventStoreContext
  def save_events events, aggregate_id, class_name
    driver.execute_in_transaction do |db|
      aggregate_access = get_aggregate_access(db)
      event_access = get_event_access(db)
      aggregate = aggregate_access.find_or_register(aggregate_id, class_name)
      event_access.store(aggregate, events)
    end
  end
  def get_aggregate_events(aggregate_id)
    driver.execute do |db|
      event_access = get_event_access(db)
      event_access.find_events_by_aggregate_id(aggregate_id)
    end
  end
  def save_snapshot aggregate_snapshot, aggregate_id, class_name; end
  def get_aggregate aggregate_id, *class_name

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
  def get_snapshot aggregate_id, *class_name; end
  def get_events aggregate_types: [], take: 0, after_sequence_number: 0, include_events: [], exclude_events: []; end
  def obsolete_snapshots class_names: [], max_event_distance: 100; end

  def get_aggregate_access(db)
    storage = Storage.new(db, context)
    AggregateAccess.new(storage)
  end

  def get_event_access(db)
    storage = Storage.new(db, context)
    EventAccess.new(storage)
  end
end