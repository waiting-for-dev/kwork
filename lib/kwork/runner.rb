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

    def call(name, *args, **kwargs)
      result = @adapter.to_kwork_result(
        @operations[name].(*args, **kwargs)
      )
      case result
      in Kwork::Result::Success[value]
        value
      in Kwork::Result::Failure
        throw :halt, @adapter.from_kwork_result(result)
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
