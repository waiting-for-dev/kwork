# frozen_string_literal: true

require "kwork/result"

module Kwork
  # @api private
  class Runner
    attr_reader :operations, :adapter, :profiler

    def initialize(operations:, adapter:, profiler:)
      @operations = operations
      @adapter = adapter
      @profiler = profiler
    end

    def __call(name, *args, **kwargs, &block)
      callback = -> { @operations[name].(*args, **kwargs, &block) }
      result = @adapter.to_kwork_result(
        @profiler.(callback, name, args, kwargs, block)
      )
      case result
      in Kwork::Result::Success[value]
        value
      in Kwork::Result::Failure
        throw :halt, result
      end
    end

    def method_missing(name, ...)
      @operations.key?(name) ? __call(name, ...) : super
    end

    def respond_to_missing?(name, include_all)
      @operations.key?(name) || super
    end
  end
end
