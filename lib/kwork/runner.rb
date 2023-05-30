# frozen_string_literal: true

module Kwork
  # Wraps operations and throws on error
  class Runner
    attr_reader :operations, :adapter

    def initialize(operations:, adapter:)
      @operations = operations
      @adapter = adapter
    end

    def call(name, *args, **kwargs)
      result = @operations[name].(*args, **kwargs)
      case result
      in [value] if result.is_a?(@adapter.success)
        value
      in ^(@adapter.failure)
        throw :halt, result
      end
    end

    def method_missing(name, *args, **kwargs)
      @operations.key?(name) ? call(name, *args, **kwargs) : super
    end

    def respond_to_missing?(name, include_all)
      @operations.key?(name) || super
    end
  end
end
