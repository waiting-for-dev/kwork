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

    # @param adapter [#from_kwork_result, #from_kwork_result] Adapter for the
    #   result type returned by the passed operations. See {Kwork::Adapters}.
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
      adapter: Adapters::Kwork,
      profiler: NULL_PROFILER,
      extension: NULL_EXTENSION,
      runner: Runner.new(instance: self, adapter:, profiler:)
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

    private

    def callback(block)
      lambda do
        catch(:halt) do
          Kwork::Result.pure(
            @runner.instance_eval(&block)
          )
        end
      end
    end
  end
end
