module SandthornDriverSequel
  class SnapshotWrapper < SimpleDelegator
    def aggregate_version
      self[:aggregate].aggregate_version
    end

    def data
      self[:aggregate]
    end

    def snapshot_id
      self[:snapshot_id]
    end

    def aggregate_table_id
      self[:aggregate_table_id]
    end
  end
end