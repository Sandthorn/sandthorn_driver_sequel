class Temp
  def save_events events, originating_aggregate_version, aggregate_id, class_name
    driver.execute_in_transaction do |db|
      aggregates = get_aggregate_access(db)
      aggregate = aggregates.find_or_register(aggregate_id, class_name)
      aggregate.store_events(events)
    end
  end
  def save_snapshot aggregate_snapshot, aggregate_id, class_name; end
  def get_aggregate_events aggregate_id, *class_name; end
  def get_aggregate aggregate_id, *class_name; end
  def get_aggregate_list_by_typename class_name; end
  def get_all_typenames; end
  def get_snapshot aggregate_id, *class_name; end
  def get_events aggregate_types: [], take: 0, after_sequence_number: 0, include_events: [], exclude_events: []; end
  def obsolete_snapshots class_names: [], max_event_distance: 100; end

  def get_aggregate_access(db)
    storage = Storage.new(db, context)
    AggregateAccess.new(storage)
  end
end