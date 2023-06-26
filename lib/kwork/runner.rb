# frozen_string_literal: true

require "kwork/result"

module Kwork
  # Wraps operations and throws on error
  class Runner
    attr_reader :operations, :adapter

    def initialize(operations:, adapter:)
      @operations = operations
      @adapter = adapter
    end

    def __call(name, ...)
      result = @adapter.to_kwork_result(
        @operations[name].(...)
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
