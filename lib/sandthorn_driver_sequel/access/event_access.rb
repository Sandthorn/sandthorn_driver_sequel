require "sandthorn_driver_sequel/access"

module SandthornDriverSequel
  class EventAccess < Access::Base
    # = EventAccess
    # Reads and writes events.

    def initialize storage, serializer, deserializer
      @serializer = serializer
      @deserializer = deserializer
      super storage
    end

    def store_events(aggregate, events)
      events = Utilities.array_wrap(events)
      timestamp = Time.now.utc
      events.each do |event|
        store_event(aggregate, timestamp, event)
      end
      aggregate.save
    end

    def find_events_by_aggregate_id(aggregate_id)
      aggregate_version = Sequel.qualify(storage.events_table_name, :aggregate_version)
      wrap(storage.events
        .join(storage.aggregates, id: :aggregate_table_id)
        .where(aggregate_id: aggregate_id)
        .select(
          :sequence_number,
          :aggregate_id,
          :aggregate_table_id,
          aggregate_version,
          :event_name,
          :event_data,
          :event_metadata,
          :timestamp)
        .order(:sequence_number)
        .all)
    end

    def get_events(*args)
      query_builder = EventQuery.new(storage)
      query_builder.build(*args)
      wrap(query_builder.events)
    end

    private

    def wrap(arg)
      events = Utilities.array_wrap(arg)
      events.each { |e| 
        e[:event_data] = deserialize(e[:event_data])
        e[:event_metadata] = deserialize(e[:event_metadata])
      }
      events.map { |e| EventWrapper.new(e.values) }
    end

    def deserialize event_data
      event_data ? @deserializer.call(event_data) : nil
    end

    def serialize event_data
      @serializer.call(event_data)
    end

    def build_event_data(aggregate, timestamp, event)
      {
        aggregate_table_id: aggregate.id,
        aggregate_version: aggregate.aggregate_version,
        event_name: event.event_name,
        event_data: serialize(event.event_data),
        event_metadata: serialize(event.event_metadata),
        timestamp: timestamp
      }
    end

    def check_versions!(aggregate, event)
      version = aggregate.aggregate_version
      if version != event[:aggregate_version]
        raise Errors::ConcurrencyError.new(event, aggregate)
      end
    rescue TypeError
      raise Errors::EventFormatError, "Event has wrong format: #{event.inspect}"
    end

    def store_event(aggregate, timestamp, event)
      event = EventWrapper.new(event)
      aggregate.aggregate_version += 1
      check_versions!(aggregate, event) if event[:aggregate_version]
      data = build_event_data(aggregate, timestamp, event)
      storage.events.insert(data)
    end

  end
end