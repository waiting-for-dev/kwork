# frozen_string_literal: true

require "kwork/executor"
require "kwork/result_adapter"

module Kwork
  # Base class to define business transactions
  class Transaction
    def self.with_delegation
      include(MethodMissing)
    end

    def initialize(
      operations:,
      adapter: ResultAdapter,
      executor: Executor.new(methods: operations, adapter: adapter)
    )
      @operations = operations
      @executor = executor
      @adapter = adapter
    end

    def transaction(&block)
      @adapter.wrap(
        catch(:halt) do
          block.(@executor)
        end
      )
    end

    # Avoids the need to call from the executor
    module MethodMissing
      def method_missing(name, *args, **kwargs)
        @operations.key?(name) ? @executor.(name, *args, **kwargs) : super
      end

      def respond_to_missing?(name, include_all)
        @operations.key?(name) || super
      end
    end
  end
end