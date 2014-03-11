require 'sequel'

module SandthornDriverSequel
  class SequelDriver
    def initialize args = {}
      @url = args.fetch(:url)
      Sequel.default_timezone = :utc
      @db = Sequel.connect(@url, :connection_handling => :stack)
    end
    def execute &block
      return block.call @db
    end
    def execute_in_transaction &block
      @db.transaction {|tr|
        return block.call @db
      }
    end

  end
end
