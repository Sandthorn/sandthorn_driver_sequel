module SandthornDriverSequel
  class EventQuery
    def initialize(storage)
      @storage = storage
    end

    def build(
      aggregate_types: [],
      take: 0,
      after_sequence_number: 0)

      aggregate_types.map!(&:to_s)

      query = storage.events
      query = add_aggregate_types(query, aggregate_types)
      query = add_sequence_number(query, after_sequence_number)
      query = add_select(query)
      query = add_limit(query, take)
      @query = query.order(:sequence_number)
    end

    def events
      @query.all
    end

    private

    attr_reader :storage

    def add_limit(query, take)
      if take > 0
        query.limit(take)
      else
        query
      end
    end

    def add_select(query)
      query.select(*select_columns)
    end

    def select_columns
      rel = Sequel.qualify(storage.events_table_name, :aggregate_version)
      [
        :aggregate_type,
        rel,
        :aggregate_id,
        :sequence_number,
        :event_name,
        :event_data,
        :event_metadata,
        :timestamp
      ]
    end

    def add_sequence_number(query, after_sequence_number)
      query.where { sequence_number > after_sequence_number }
    end

    def add_aggregate_types(query, aggregate_types)
      if aggregate_types.any?
        query.join(storage.aggregates, id: :aggregate_table_id, aggregate_type: aggregate_types)
      else
        query.join(storage.aggregates, id: :aggregate_table_id)
      end
    end

  end
end