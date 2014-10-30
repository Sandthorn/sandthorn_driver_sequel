module SandthornDriverSequel
  class EventAccess < Access

    def store_events(aggregate, events)
      timestamp = Time.now.utc
      events.each do |event|
        store_event(aggregate, timestamp, event)
      end
      aggregate.save
    end

    def find_events_by_aggregate_id(aggregate_id)
      storage.events.join(storage.aggregates, id: :aggregate_table_id).where(aggregate_id: aggregate_id).all
    end

    private

    def build_event_data(aggregate, timestamp, event)
      {
          aggregate_table_id: aggregate.id,
          aggregate_version: event.aggregate_version,
          event_name: event.event_name,
          event_data: event.event_data,
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
      event = Event.new(event)
      aggregate.aggregate_version += 1
      check_versions!(aggregate, event)
      data = build_event_data(aggregate, timestamp, event)
      storage.events.insert(data)
    end

  end
end