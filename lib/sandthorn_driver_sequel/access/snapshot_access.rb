module SandthornDriverSequel
  class SnapshotAccess < Access::Base

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
      if snapshot
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

    class SnapshotWrapper < SimpleDelegator
      def aggregate_version
        self[:aggregate_version]
      end

      def data
        self[:event_data]
      end
    end

  end
end
