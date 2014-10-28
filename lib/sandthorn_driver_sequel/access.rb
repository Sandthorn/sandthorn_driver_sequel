module SandthornDriverSequel
  class Access
    def initialize(storage)
      @storage = storage
    end

    private

    attr_reader :storage
  end

end