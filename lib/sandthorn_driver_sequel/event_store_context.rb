module SandthornDriverSequel
  module EventStoreContext
    attr_reader :context

    def events_table_name
      with_context_if_exists :events
    end

    def aggregates_table_name
      with_context_if_exists :aggregates
    end

    def with_context_if_exists name
      name = "#{context}_#{name}".to_sym if context
      name
    end
  end
end