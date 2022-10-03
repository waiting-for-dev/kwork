# frozen_string_literal: true

require "kwork/executor"
require "kwork/result_adapter"

module Kwork
  # Base class to define business transactions
  class Transaction
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
  end
end
