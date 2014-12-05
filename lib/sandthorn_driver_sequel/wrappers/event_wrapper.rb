require 'delegate'
module SandthornDriverSequel
  class EventWrapper < SimpleDelegator

    [:aggregate_version, :event_name, :event_data, :timestamp, :aggregate_table_id].each do |attribute|
      define_method(attribute) do
        fetch(attribute)
      end
    end

  end
end