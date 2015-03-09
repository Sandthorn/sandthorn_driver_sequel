module SandthornDriverSequel
  class Storage
    # = Storage
    # Abstracts access to contextualized database tables.
    #
    # == Rationale
    # Provide object-oriented access to the different tables to other objects.
    # Make it unnecessary for them to know about the current context.
    include EventStoreContext

    attr_reader :db

    def initialize(db, context)
      @db = db
      @context = context
    end

    # Returns a Sequel::Model for accessing aggregates
    def aggregates
      Class.new(Sequel::Model(aggregates_table))
    end

    # Returns a Sequel::Model for accessing events
    def events
      Class.new(Sequel::Model(events_table))
    end

    # Returns a Sequel::Model for accessing snapshots
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