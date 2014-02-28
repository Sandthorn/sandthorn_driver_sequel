require 'sequel'

module SandthornDriverSequel
  class SequelDriver
    def initialize args = {}
      @url = args.fetch(:url)
      Sequel.default_timezone = :utc
    end
    def execute &block
      Sequel.connect(@url) { |db| return block.call db}
    end
    def execute_in_transaction &block
      Sequel.connect(@url) do |db|
        db.transaction do
          return block.call db
        end
      end
    end 
  end
end
