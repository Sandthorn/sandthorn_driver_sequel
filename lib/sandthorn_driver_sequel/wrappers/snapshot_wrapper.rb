module SandthornDriverSequel
  class SnapshotWrapper < SimpleDelegator
    def aggregate_version
      self[:aggregate_version]
    end

    def data
      self[:snapshot_data]
    end
  end
end