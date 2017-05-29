require "sandthorn_driver_sequel/access"

module SandthornDriverSequel
  class AggregateAccess < Access::Base

    def find_or_register(aggregate_id, aggregate_type)
      if aggregate = find_by_aggregate_id(aggregate_id)
        aggregate
      else
        register_aggregate(aggregate_id, aggregate_type)
      end
    end

    # Create a database row for an aggregate.
    # Return the row.
    def register_aggregate(aggregate_id, aggregate_type)
      id = storage.aggregates.insert(aggregate_id: aggregate_id, aggregate_type: aggregate_type.to_s)
      find(id)
    end

    # Find by database table id.
    def find(id)
      storage.aggregates[id]
    end

    def find_by_aggregate_id(aggregate_id)
      storage.aggregates.first(aggregate_id: aggregate_id)
    end

    # Throws an error if the aggregate isn't registered.
    def find_by_aggregate_id!(aggregate_id)
      aggregate = find_by_aggregate_id(aggregate_id)
      raise Errors::NoAggregateError, aggregate_id unless aggregate
      aggregate
    end

    # Returns aggregate ids.
    # @param aggregate_type, optional,
    def aggregate_ids(aggregate_type: nil)
      aggs = storage.aggregates
      if aggregate_type
        aggs = aggs.where(aggregate_type: aggregate_type.to_s)
      end
      aggs.order(:id).select_map(:aggregate_id)
    end

  end
end