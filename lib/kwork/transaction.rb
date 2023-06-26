# frozen_string_literal: true

require "kwork/result"
require "kwork/runner"
require "kwork/adapters/kwork"

module Kwork
  # Base class to define business transactions
  class Transaction
    NULL_EXTENSION = ->(&block) { block.() }

    attr_reader :runner, :extension

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
          Kwork::Result.pure(
            block.(@runner)
          )
        end
      end

      @runner.adapter.from_kwork_result(result)
    end

    def merge_operations(**operations)
      new_operations = @runner.operations.merge(operations)

      self.class.new(
        operations: new_operations,
        adapter: @runner.adapter,
        extension: @extension
      )
    end
  end
end
