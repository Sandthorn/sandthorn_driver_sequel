module SandthornDriverSequel
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

    def aggregate_types
      storage.aggregates.select(:aggregate_type).distinct.select_map(:aggregate_type)
    end

    def aggregate_ids(type: nil)
      aggs = storage.aggregates
      if type
        aggs = aggs.where(aggregate_type: type)
      end
      aggs.order(:id).select_map(:aggregate_id)
    end

  end
end