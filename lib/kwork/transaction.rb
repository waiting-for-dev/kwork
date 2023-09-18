# frozen_string_literal: true

require "kwork/result"
require "kwork/adapters/kwork"
require "transactable"

module Kwork
  # Represents a transaction
  class Transaction
    include Transactable

    # @api private
    NULL_EXTENSION = ->(callback) { callback.() }

    # @api private
    attr_reader :extension

    # @param adapter [#from_kwork_result, #from_kwork_result] Adapter for the
    #   result type returned by the passed operations. See {Kwork::Adapters}.
    # @param extension [#call] Wrapper for the whole transaction. It takes a
    #   callback which represents the raw transaction. Its result needs to be
    #   returned.
    def initialize(
      adapter: Adapters::Kwork,
      extension: NULL_EXTENSION
    )
      @adapter = adapter
      @extension = extension
    end

    # Executes the given transaction
    #
    # @param block [Proc] The transaction to be executed
    def transaction(&block)
      result = @extension.(callback(block))

      @adapter.from_kwork_result(result)
    end

    # Acts according a step in the transaction
    #
    # When a failure is found, the transaction is halted and that one is
    # returned.
    #
    # @param result [Any] A result from a operation
    # @return [Kwork::Result]
    def step(result)
      result = @adapter.to_kwork_result(result)
      case result
      in Kwork::Result::Success[value]
        value
      in Kwork::Result::Failure
        throw :halt, result
      end
    end

    # Acts according a pipe of {Transactable} operations
    #
    # When a failure is found, the transaction is halted and that one is
    # returned.
    #
    # For now, it only works when using the Dry::Monads::Maybe adapter
    #
    # @params [<Any>] Transactable operations
    # @return [Kwork::Result]
    def pipe(...)
      step super
    end

    private

    def callback(block)
      lambda do
        catch(:halt) do
          Kwork::Result.pure(
            block.()
          )
        end
      end
    end
  end
end
