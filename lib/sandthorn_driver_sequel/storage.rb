class Storage
  include EventStoreContext

  def initialize(db, context)
    @db = db
    @context = context
  end

  def aggregates
    Class.new(Sequel::Model(aggregates_table)) do
      def 
    end
  end

  def aggregates_table
    db[aggregates_table_name]
  end


end