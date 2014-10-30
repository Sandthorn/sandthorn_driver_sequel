module SandthornDriverSequel
  module Access
    class Base
      def initialize(storage)
        @storage = storage
      end

      private

      attr_reader :storage
    end
  end
end

require "sandthorn_driver_sequel/access/aggregate_access"
require "sandthorn_driver_sequel/access/event_access"
require "sandthorn_driver_sequel/access/snapshot_access"