require "sandthorn_driver_sequel/access"

module SandthornDriverSequel
  class SnapshotAccess < Access::Base

    def initialize storage, serializer, deserializer
      @serializer = serializer
      @deserializer = deserializer
      super storage
    end

    def find_by_aggregate_id(aggregate_id)
      
      aggregate_from_table = aggregates.find_by_aggregate_id(aggregate_id)
      return nil if aggregate_from_table.nil?
      snapshot = storage.snapshots.first(aggregate_table_id: aggregate_from_table.id)
      if snapshot
        aggregate = deserialize(snapshot[:snapshot_data])
        
        snapshot_data = {
          aggregate: aggregate,
          snapshot_id: snapshot.id,
          aggregate_table_id: snapshot[:aggregate_table_id]
        }
        return SnapshotWrapper.new(snapshot_data)
      end
      
      return nil
    end

    def find(snapshot_id)
      
      snapshot = storage.snapshots[snapshot_id]
      aggregate = deserialize(snapshot[:snapshot_data])

      snapshot_data = {
        aggregate: aggregate,
        snapshot_id: snapshot_id,
        aggregate_table_id: snapshot[:aggregate_table_id]
      }
      
      SnapshotWrapper.new(snapshot_data)
    end

    def record_snapshot(aggregate)
      aggregate_from_table = aggregates.find_by_aggregate_id!(aggregate.aggregate_id)
      perform_snapshot(aggregate, aggregate_from_table.id)
    end

    def obsolete(aggregate_types: [], max_event_distance: 100)
      aggregate_types.map!(&:to_s)
      snapshot_version = Sequel.qualify(storage.snapshots_table_name, :aggregate_version)
      aggregate_version = Sequel.qualify(storage.aggregates_table_name, :aggregate_version)
      query = storage.aggregates.left_outer_join(storage.snapshots, aggregate_table_id: :id)
      query = query.select { (aggregate_version - snapshot_version).as(distance) }
      query = query.select_append(:aggregate_id, :aggregate_type)
      query = query.where { (aggregate_version - coalesce(snapshot_version, 0)) > max_event_distance }
      if aggregate_types.any?
        query = query.where(aggregate_type: aggregate_types)
      end
      query.all
    end

    private

    def aggregates
      @aggregates ||= AggregateAccess.new(storage)
    end

    def perform_snapshot(aggregate, aggregate_table_id) 
      current_snapshot = storage.snapshots.first(aggregate_table_id: aggregate_table_id)
      snapshot = build_snapshot(aggregate)
      if current_snapshot
        update_snapshot(snapshot, current_snapshot.id)
      else
        insert_snapshot(snapshot, aggregate_table_id)
      end
    end

    def build_snapshot(aggregate)
      {
        snapshot_data:      serialize(aggregate),
        aggregate_version:  aggregate.aggregate_version
      }
    end

    def insert_snapshot(snapshot, id)
      snapshot[:aggregate_table_id] = id
      storage.snapshots.insert(snapshot)
    end

    def update_snapshot(snapshot, id)
      storage.snapshots.where(id: id).update(snapshot)
    end

    def serialize aggregate
      @serializer.call(aggregate)
    end

    def deserialize snapshot_data
      @deserializer.call(snapshot_data)
    end

  end
end
