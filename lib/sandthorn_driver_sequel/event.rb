require 'delegate'
module SandthornDriverSequel
  class Event < SimpleDelegator

    [:aggregate_version, :event_name, :event_data].each do |attribute|
      define_method(attribute) do
        fetch(attribute)
      end
    end

  end
end