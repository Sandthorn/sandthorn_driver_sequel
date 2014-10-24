module SandthornDriverSequel::Errors
  class Error < StandardError; end
  class ConcurrencyError < Error
    attr_reader :event, :aggregate_type, :version
    def initialize(event, aggregate_type, version)
      @event = event
      @aggregate_type = aggregate_type
      @version = version
      super(create_message)
    end

    def create_message
      "#{event[:aggregate_type]} with id #{event[:aggregate_id]}: " +
      "expected event with version #{version}, but got #{event[:aggregate_version]}"
    end
  end
  class InternalError < Error; end
  class NoAggregateError < Error; end
  class WrongAggregateVersionError < Error;
    def initialize(aggregate, version)
      @aggregate = aggregate
      @version = version
      super(create_message)
    end

    def create_message
      "#{@aggregate[:aggregate_type]} with id #{@aggregate[:aggregate_id]}" +
      " should be at version #{@version}" +
      " but was #{@aggregate[:aggregate_version]} in the event store."
    end
  end

  class WrongSnapshotVersionError < Error
    attr_reader :aggregate, :version
    def initialize(aggregate, version)
      @aggregate = aggregate
      @version = version
      super(create_message)
    end

    def create_message
      "#{aggregate[:aggregate_type]} with id #{aggregate[:aggregate_id]}: tried to save snapshot with version "+
      "#{version}, but current version is at #{aggregate[:aggregate_version]}"
    end
  end

end    
