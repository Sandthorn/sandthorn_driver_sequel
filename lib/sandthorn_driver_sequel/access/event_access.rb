module SandthornDriverSequel
  class EventAccess < Access::Base
    using Refinements::Array

    def store_events(aggregate, events)
      events = Array.wrap(events)
      timestamp = Time.now.utc
      events.each do |event|
        store_event(aggregate, timestamp, event)
      end
      aggregate.save
    end

    def find_events_by_aggregate_id(aggregate_id)
      aggregate_version = Sequel.qualify(storage.events_table_name, :aggregate_version)
      storage.events
        .join(storage.aggregates, id: :aggregate_table_id)
        .where(aggregate_id: aggregate_id)
        .select(
          :sequence_number,
          :aggregate_id,
          :aggregate_table_id,
          aggregate_version,
          :event_name,
          :event_data,
          :timestamp)
        .all
    end

    # Returns events from the most recent snapshot
    def after_snapshot(snapshot)
      _aggregate_version = snapshot.aggregate_version
      aggregate_table_id = snapshot.aggregate_table_id
      storage.events
        .where(aggregate_table_id: aggregate_table_id)
        .where { aggregate_version > _aggregate_version }.all
    end

    def get_events(*args)
      query_builder = EventQuery.new(storage)
      query_builder.build(*args)
      query_builder.events
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