# frozen_string_literal: true

require "kwork/executor"
require "kwork/adapter/result"

module Kwork
  # Base class to define business transactions
  class Transaction
    NULL_EXTENSION = ->(&block) { block.() }

    attr_reader :executor

    def self.with_delegation
      include(MethodMissing)
    end

    def initialize(
      operations:,
      adapter: Adapter::Result,
      executor: Executor.new(operations:, adapter:),
      extension: NULL_EXTENSION
    )
      @executor = executor
      @extension = extension
    end

    def transaction(&block)
      result = nil
      @extension.() do
        result = catch(:halt) do
          @executor.adapter.wrap_success(
            block.(@executor)
          )
        end
      end
      result
    end

    def with(**operations)
      new_operations = @executor.operations.merge(operations)

      self.class.new(
        operations: new_operations,
        adapter: @executor.adapter
      )
    end

    # Avoids the need to call from the executor
    module MethodMissing
      def method_missing(name, *args, **kwargs)
        executor.operations.key?(name) ? executor.(name, *args, **kwargs) : super
      end

      def respond_to_missing?(name, include_all)
        executor.operations.key?(name) || super
      end
    end
  end
end
