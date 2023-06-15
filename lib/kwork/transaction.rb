# frozen_string_literal: true

require "kwork/runner"
require "kwork/adapters/kwork"

module Kwork
  # Base class to define business transactions
  class Transaction
    NULL_EXTENSION = ->(&block) { block.() }

    attr_reader :runner

    def initialize(
      operations:,
      adapter: Adapters::Kwork,
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
  end
end
