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

      
    end
  end
end
