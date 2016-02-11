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

      if block_given?
        configuration = Configuration.new
        yield(configuration)
      else
        configuration = self.configuration
      end

      EventStore.from_url(url, configuration, context)
    end

    def driver_from_connection connection: nil, context: nil
      if block_given?
        configuration = Configuration.new
        yield(configuration)
      else
        configuration = self.configuration
      end
      EventStore.new(SequelDriver.new(connection: connection), configuration, context)
    end

    def configure
      yield(configuration) if block_given?
    end

    def configuration
      @configuration ||= Configuration.new
    end

    private

    class Configuration

      #event
      def event_serializer=(block)
        @event_serializer = block
      end

      def event_deserializer=(block)
        @event_deserializer = block
      end

      def event_serializer
        @event_serializer || default_event_serializer
      end

      def event_deserializer
        @event_deserializer || default_event_deserializer
      end

      def default_event_serializer
        -> (data) { YAML.dump(data) }
      end

      def default_event_deserializer
        -> (data) { YAML.load(data) }
      end

      #snapshot
      def snapshot_serializer=(block)
        @snapshot_serializer = block
      end

      def snapshot_deserializer=(block)
        @snapshot_deserializer = block
      end

      def snapshot_serializer
        @snapshot_serializer || default_snapshot_serializer
      end

      def snapshot_deserializer
        @snapshot_deserializer || default_snapshot_deserializer
      end

      def default_snapshot_serializer
        -> (data) { YAML.dump(data) }
      end

      def default_snapshot_deserializer
        -> (data) { YAML.load(data) }
      end

      
    end
  end
end
