module SandthornDriverSequel::Errors
    class Error < StandardError; end
    class ConcurrencyError < Error; end
    class InternalError < Error; end
    class NoAggregateError < Error; end
    class WrongAggregateVersionError < Error; end
end    
