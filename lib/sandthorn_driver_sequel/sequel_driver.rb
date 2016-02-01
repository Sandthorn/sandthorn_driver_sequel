require 'sequel'

module SandthornDriverSequel
  class SequelDriver

    def initialize args = {}
      url = args.fetch(:url,nil)
      connection = args.fetch(:connection,nil)
      Sequel.default_timezone = :utc
      @db = connection || Sequel.connect(url)
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
