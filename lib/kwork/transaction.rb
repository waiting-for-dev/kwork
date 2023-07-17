# frozen_string_literal: true

require "kwork/result"
require "kwork/runner"
require "kwork/adapters/kwork"

module Kwork
  # Represents a transaction
  class Transaction
    # @api private
    NULL_EXTENSION = ->(callback) { callback.() }

    # @api private
    NULL_PROFILER = ->(callback, _name, _args, _kwargs, _block) { callback.() }

    # @api private
    attr_reader :runner,
                :extension

    # @param operations [Hash{Symbol => #call}] Map of names and callables returning a result type
    # @param adapter [#from_kwork_result, #from_kwork_result] Adapter for the
    #   result type returned by the given operations. See {Kwork::Adapters}.
    # @param profiler [#call] Profiler wrapping every operation. It takes the following arguments:
    #   - {Proc}: A callback wrapping the execution of an operation. Its result
    #   needs to be returned by the profiler.
    #   - {Symbol}: The name of the operation being executed
    #   - {Array}: The positional arguments of the operation being executed
    #   - {Hash}: The keyword arguments of the operation being executed
    #   - {Proc}: The block of the operation being executed
    # @param extension [#call] Wrapper for the whole transaction. It takes a
    #   callback which represents the raw transaction. Its result needs to be
    #   returned.
    def initialize(
      operations:,
      adapter: Adapters::Kwork,
      profiler: NULL_PROFILER,
      extension: NULL_EXTENSION,
      runner: Runner.new(operations:, adapter:, profiler:)
    )
      @runner = runner
      @extension = extension
    end

    # Executes the given transaction
    #
    # Wraps the execution in the extension and returns the result. Every
    # operation execution is given in the given profiler.
    #
    # @param block [Proc] The transaction to be executed
    def transaction(&block)
      result = @extension.(callback(block))

      @runner.adapter.from_kwork_result(result)
    end

    # Merges given operations
    #
    # It returns a new instance with the new operations merged.
    #
    # @param operations [#call] List of callables returning a result type
    def merge_operations(**operations)
      new_operations = @runner.operations.merge(operations)

      self.class.new(
        operations: new_operations,
        adapter: @runner.adapter,
        extension: @extension,
        profiler: @runner.profiler
      )
    end

    private

    def callback(block)
      lambda do
        catch(:halt) do
          Kwork::Result.pure(
            block.(@runner)
          )
        end
      end
    end
  end
end
