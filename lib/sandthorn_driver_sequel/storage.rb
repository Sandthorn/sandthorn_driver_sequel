module SandthornDriverSequel
  class Storage
    include EventStoreContext

    attr_reader :db

    def initialize(db, context)
      @db = db
      @context = context
    end

    def aggregates
      Class.new(Sequel::Model(aggregates_table))
    end

    def events
      Class.new(Sequel::Model(events_table))
    end

    def snapshots
      Class.new(Sequel::Model(snapshots_table))
    end

    def aggregates_table
      db[aggregates_table_name]
    end

    def events_table
      db[events_table_name]
    end

    def snapshots_table
      db[snapshots_table_name]
    end

  end
end