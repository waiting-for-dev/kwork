# frozen_string_literal: true

require "kwork/runner"
require "kwork/adapter/result"

module Kwork
  # Base class to define business transactions
  class Transaction
    NULL_EXTENSION = ->(&block) { block.() }

    attr_reader :runner

    def self.with_delegation
      include(MethodMissing)
    end

    def initialize(
      operations:,
      adapter: Adapter::Result,
      runner: Runner.new(operations:, adapter:),
      extension: NULL_EXTENSION
    )
      @runner = runner
      @extension = extension
    end

    def transaction(&block)
      result = nil
      @extension.() do
        result = catch(:halt) do
          @runner.adapter.wrap_success(
            block.(@runner)
          )
        end
      end
      result
    end

    def with(**operations)
      new_operations = @runner.operations.merge(operations)

      self.class.new(
        operations: new_operations,
        adapter: @runner.adapter
      )
    end

    # Avoids the need to call from the runner
    module MethodMissing
      def method_missing(name, *args, **kwargs)
        runner.operations.key?(name) ? runner.(name, *args, **kwargs) : super
      end

      def respond_to_missing?(name, include_all)
        runner.operations.key?(name) || super
      end
    end
  end
end
