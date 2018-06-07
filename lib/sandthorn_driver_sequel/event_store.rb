require "sandthorn_driver_sequel/access/aggregate_access"
require "sandthorn_driver_sequel/access/event_access"
require "sandthorn_driver_sequel/storage"

module SandthornDriverSequel
  class EventStore
    include EventStoreContext

    attr_reader :driver, :context

    def initialize connection, configuration, context = nil
      @driver = connection
      @context = context
      @event_serializer = configuration.event_serializer
      @event_deserializer = configuration.event_deserializer
    end

    def self.from_url url, configuration, context = nil
      new(SequelDriver.new(url: url), configuration, context)
    end

    #save methods
    def save_events events, aggregate_id, class_name
      driver.execute_in_transaction do |db|
        aggregates = get_aggregate_access(db)
        event_access = get_event_access(db)
        aggregate = aggregates.find_or_register(aggregate_id, class_name)
        event_access.store_events(aggregate, events)
      end
    end

    #get methods
    def all aggregate_type
      return get_aggregate_ids(aggregate_type: aggregate_type).map do |id|
        aggregate_events(id)
      end
    end

    def find aggregate_id, aggregate_type, after_aggregate_version = 0
      aggregate_events(aggregate_id, after_aggregate_version)
    end

    def get_events(*args)
      driver.execute do |db|
        event_access = get_event_access(db)
        event_access.get_events(*args)
      end
    end

    private

    def aggregate_events(aggregate_id, after_aggregate_version = 0)
      driver.execute do |db|
        event_access = get_event_access(db)
        event_access.find_events_by_aggregate_id(aggregate_id, after_aggregate_version)
      end
    end

    def get_aggregate_ids(aggregate_type: nil)
      driver.execute do |db|
        access = get_aggregate_access(db)
        access.aggregate_ids(aggregate_type: aggregate_type)
      end
    end

    def get_aggregate_access(db)
      @aggregate_access ||= AggregateAccess.new(storage(db))
    end

    def get_event_access(db)
      @event_access ||= EventAccess.new(storage(db), @event_serializer, @event_deserializer)
    end

    def storage(db)
      @storage ||= Storage.new(db, @context)
    end

  end
end