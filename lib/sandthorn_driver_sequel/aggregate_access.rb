require File.expand_path(File.dirname(__FILE__) + '/access.rb')
class AggregateAccess < Access

  def find_or_register(aggregate_id, aggregate_type)
    if aggregate = find_by_aggregate_id(aggregate_id)
      aggregate
    else
      register_aggregate(aggregate_id, aggregate_type)
    end
  end

  def register_aggregate(aggregate_id, aggregate_type)
    id = storage.aggregates.insert(aggregate_id: aggregate_id, aggregate_type: aggregate_type.to_s)
    find(id)
  end

  def find(id)
    storage.aggregates[id]
  end

  def find_by_aggregate_id(aggregate_id)
    storage.aggregates.first(aggregate_id: aggregate_id)
  end

end