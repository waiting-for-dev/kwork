# frozen_string_literal: true

require "kwork/result"

module Kwork
  # @api private
  class Runner
    attr_reader :instance, :adapter, :profiler

    def initialize(instance:, adapter:, profiler:)
      @instance = instance
      @adapter = adapter
      @profiler = profiler
    end

    def step(result)
      case result
      in Kwork::Result::Success[value]
        value
      in Kwork::Result::Failure
        throw :halt, result
      end
    end

    def __call(name, *args, **kwargs, &block)
      callback = -> { @instance.method(name).(*args, **kwargs, &block) }
      @adapter.to_kwork_result(
        @profiler.(callback, name, args, kwargs, block)
      )
    end

    def method_missing(name, ...)
      @instance.method(name) ? __call(name, ...) : super
    end

    def respond_to_missing?(name, include_all)
      @instance.key?(name) || super
    end
  end
end
