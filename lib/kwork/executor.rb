# frozen_string_literal: true

module Kwork
  # Wraps operations and throws on error
  class Executor
    def initialize(methods:, adapter:)
      @methods = methods
      @adapter = adapter
    end

    def call(name, *args, **kwargs)
      result = @methods[name].(*args, **kwargs)

      if @adapter.success?(result)
        @adapter.unwrap(result)
      else
        throw :halt, result
      end
    end

    def method_missing(name, *args, **kwargs)
      @methods.key?(name) ? call(name, *args, **kwargs) : super
    end

    def respond_to_missing?(name, include_all)
      @methods.key?(name) || super
    end
  end
end
