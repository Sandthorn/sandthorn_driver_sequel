module SandthornDriverSequel::Errors
  Error = Class.new(StandardError)
  InternalError = Class.new(Error)
  NoAggregateError = Class.new(Error)

  class ConcurrencyError < Error
    attr_reader :event, :aggregate
    def initialize(event, aggregate)
      @event = event
      @aggregate = aggregate
      super(create_message)
    end

    def create_message
      "#{aggregate.aggregate_type} with id #{aggregate.aggregate_id}: " +
      "expected event with version #{aggregate.aggregate_version}, but got #{event.aggregate_version}"
    end
  end

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
