class AggregateAccess

  def initialize(storage)
    @storage = storage
  end

  def find_or_register(aggregate_id, aggregate_type)
    return aggregate if aggregate = find(aggregate)
    register_aggregate(aggregate_id, aggregate_type)
  end

  def register_aggregate(aggregate_id, aggregate_type)
    storage.aggregates.insert(aggregate_id: aggregate_id, aggregate_type: aggregate_type.to_s)
  end

  def find_by_aggregate_id(aggregate_id)
    storage.aggregates.first(aggregate_id: aggregate_id)
  end

  private

  attr_reader :storage
end