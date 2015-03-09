module SandthornDriverSequel
  class SnapshotWrapper < SimpleDelegator
    def aggregate_version
      self[:aggregate_version]
    end

    def data
      self[:event_data]
    end
  end
end