require 'sequel'

module SandthornDriverSequel
  class SequelDriver

    def initialize(args = {})
      Sequel.default_timezone = :utc
      @db = args.fetch(:connection) {
        Sequel.connect(args.fetch(:url))
      }
    end

    def execute
      yield @db
    end

    def execute_in_transaction &block
      @db.transaction do
        block.call(@db)
      end
    end

  end
end
