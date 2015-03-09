require 'sequel'

module SandthornDriverSequel
  class SequelDriver

    def initialize args = {}
      @url = args.fetch(:url)
      Sequel.default_timezone = :utc
      @db = Sequel.connect(@url)
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
