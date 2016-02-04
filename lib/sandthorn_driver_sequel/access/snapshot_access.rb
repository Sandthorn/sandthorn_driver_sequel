require "sandthorn_driver_sequel/access"

module SandthornDriverSequel
  class SnapshotAccess < Access::Base

    def initialize storage, serializer, deserializer
      @serializer = serializer
      @deserializer = deserializer
      super storage
    end

    def find_by_aggregate_id(aggregate_id)
      aggregate = aggregates.find_by_aggregate_id(aggregate_id)
      storage.snapshots.first(aggregate_table_id: aggregate.id)
    end

    def find(snapshot_id)
      storage.snapshots[snapshot_id]
    end

    def record_snapshot(aggregate_id, snapshot_data)
      aggregate = aggregates.find_by_aggregate_id!(aggregate_id)
      previous_snapshot = find_by_aggregate_id(aggregate_id)
      if perform_snapshot?(aggregate, previous_snapshot)
        perform_snapshot(aggregate, previous_snapshot, snapshot_data)
      end
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

    def perform_snapshot?(aggregate, snapshot)
      return true if snapshot.nil?
      snapshot = SnapshotWrapper.new(snapshot)
      aggregate.aggregate_version > snapshot.aggregate_version
    end

    def perform_snapshot(aggregate, snapshot, snapshot_data)
      check_snapshot_version!(aggregate, snapshot_data)
      if valid_snapshot?(snapshot)
        update_snapshot(snapshot, snapshot_data)
      else
        insert_snapshot(aggregate, snapshot_data)
      end
    end

    def insert_snapshot(aggregate, snapshot_data)
      data = build_snapshot(snapshot_data)
      data[:aggregate_table_id] = aggregate.id
      storage.snapshots.insert(data)
    end

    def build_snapshot(snapshot_data)
      snapshot_data = SnapshotWrapper.new(snapshot_data)
      {
          snapshot_data:      snapshot_data.data,
          aggregate_version:  snapshot_data.aggregate_version
      }
    end

    def valid_snapshot?(snapshot)
      snapshot && snapshot[:snapshot_data]
    end

    def update_snapshot(snapshot, snapshot_data)
      data = build_snapshot(snapshot_data)
      storage.snapshots.where(id: snapshot.id).update(data)
    end

    def check_snapshot_version!(aggregate, snapshot_data)
      snapshot = SnapshotWrapper.new(snapshot_data)
      if aggregate.aggregate_version < snapshot.aggregate_version
        raise Errors::WrongSnapshotVersionError.new(aggregate, snapshot.aggregate_version)
      end
    end

  end
end
