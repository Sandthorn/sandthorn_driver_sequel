require "sandthorn_driver_sequel/version"
require "sandthorn_driver_sequel/event_store_context"
require 'sandthorn_driver_sequel/event_store'
require 'sandthorn_driver_sequel/errors'
require 'sandthorn_driver_sequel/migration'

module SandthornDriverSequel
  class << self
    def driver_from_url url: nil, context: nil
      EventStore.new url: url, context: context
    end
    def migrate_db url: nil, context: nil
      migrator = Migration.new url: url, context: context
      migrator.migrate!
    end
  end
end
