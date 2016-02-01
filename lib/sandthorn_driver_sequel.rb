require "sandthorn_driver_sequel/version"
require "sandthorn_driver_sequel/utilities"
require "sandthorn_driver_sequel/wrappers"
require "sandthorn_driver_sequel/event_query"
require "sandthorn_driver_sequel/event_store_context"
require 'sandthorn_driver_sequel/event_store'
require 'sandthorn_driver_sequel/errors'
require 'sandthorn_driver_sequel/migration'
require 'yaml'

module SandthornDriverSequel
  class << self
    
    def migrate_db url: nil, context: nil
      migrator = Migration.new url: url, context: context
      migrator.migrate!
    end

    def driver_from_url url: nil, context: nil
      yield(session_configure) if block_given?
      driver = EventStore.new url: url, context: context, event_serializer: configuration.event_serializer, event_deserializer: configuration.event_deserializer
      @session_configuration = nil
      return driver
    end

    def driver_from_connection connection: nil, context: nil
      yield(session_configure) if block_given?
      driver = EventStore.new connection: connection, context: context, event_serializer: configuration.event_serializer, event_deserializer: configuration.event_deserializer
      @session_configuration = nil
      return driver
    end

    def configure
      yield(configuration) if block_given?
    end

    private

    def session_configure
      @session_configuration ||= Configuration.new 
    end

    def configuration
      @session_configuration || @configuration ||= Configuration.new
    end

    class Configuration

      def event_serializer=(block)
        @serializer = block
      end

      def event_deserializer=(block)
        @deserializer = block
      end

      def event_serializer
        @serializer || default_event_serializer
      end

      def event_deserializer
        @deserializer || default_event_deserializer
      end

      def default_event_serializer
        -> (data) { YAML.dump(data) }
      end

      def default_event_deserializer
        -> (data) { YAML.load(data) }
      end

      def serialize_event(data)
        event_serializer.call(data)
      end

      def deserialize_event(data)
        event_deserializer.call(data)
      end

    end
  end
end
