require 'sandthorn_driver_sequel/sequel_driver'
module SandthornDriverSequel
  class Migration
    include EventStoreContext
    attr_reader :driver, :context
    def initialize url: nil, connection: nil, context: nil
      @driver = SequelDriver.new url: url, connection: connection
      @context = context
    end
    def migrate!
      ensure_migration_table!
      aggregates
      events
      snapshots
    end
    private
    def clear_for_test
      driver.execute do |db|
        db[snapshots_table_name].truncate
        db[events_table_name].truncate
        db[aggregates_table_name].truncate
      end
    end
    def aggregates
      aggr_migration_0 = "#{aggregates_table_name}-20130308"
      unless has_been_migrated?(aggr_migration_0)
        driver.execute_in_transaction do |db|
          db.create_table(aggregates_table_name) do
            primary_key :id
            String :aggregate_id, fixed: true, size: 36, null: false
            Integer :aggregate_version, null: false
            String :aggregate_type, size: 255, null: false
            index [:aggregate_type]
            index [:aggregate_type, :aggregate_id], unique: true
            index [:aggregate_id], unique: true
          end
          was_migrated aggr_migration_0, db
        end
      end
      aggr_migration_1 = "#{aggregates_table_name}-20141024"
      unless has_been_migrated?(aggr_migration_1)
        driver.execute do |db|
          db.alter_table(aggregates_table_name) do
            set_column_default :aggregate_version, 0
          end
        end
      end

    end
    def events
      events_migration_0 = "#{events_table_name}-20130308"
      unless has_been_migrated?(events_migration_0)
        driver.execute_in_transaction do |db|
          aggr_table = aggregates_table_name
          db.create_table(events_table_name) do
            primary_key :sequence_number
            foreign_key :aggregate_table_id, aggr_table, on_update: :cascade
            Integer :aggregate_version, null: false
            String :event_name, size: 255, null: false
            String :event_data, text: true, null: true
            DateTime :timestamp, null: false

            index [:event_name]
          end
          was_migrated events_migration_0, db
        end
      end

      events_migration_1 = "#{events_table_name}-20131004"
      unless has_been_migrated?(events_migration_1)
        driver.execute_in_transaction do |db|
          db.alter_table events_table_name do
            add_index [:aggregate_table_id]
            add_index [:aggregate_table_id,:aggregate_version], unique: true
          end
          was_migrated events_migration_1, db
        end
      end
    end
    def snapshots
      snapshot_migration_0 = "#{snapshots_table_name}-20130312"
      unless has_been_migrated?(snapshot_migration_0)
        driver.execute_in_transaction do |db|
          aggr_table = aggregates_table_name
          db.create_table(snapshots_table_name) do
            primary_key :id
            Integer :aggregate_version, null: false
            String :snapshot_data, text: true, null: false
            foreign_key :aggregate_table_id, aggr_table, on_delete: :cascade, on_update: :cascade
            index [:aggregate_table_id], unique: true
          end
          was_migrated snapshot_migration_0, db
        end
      end
    end

    def migration_table_name
      :event_store_sequel_migrations
    end
    def ensure_migration_table!
      driver.execute do |db|
        db.create_table?(migration_table_name) do
          primary_key :id
          String :migration_name, null: false
          index [:migration_name], unique: true
          DateTime :timestamp, :null=>false
        end
      end
    end
    def has_been_migrated? migration_name
      driver.execute {|db| db[migration_table_name].all.any? { |e| e[:migration_name]==migration_name } }
    end
    def was_migrated migration_name, db
      db[migration_table_name].insert timestamp: Time.now.utc, migration_name: migration_name
    end
  end
end
