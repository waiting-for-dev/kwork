# frozen_string_literal: true

require_relative "kwork/version"
require_relative "kwork/transaction"

# DSL usage for a {Kwork::Transaction}
module Kwork
  class Error < StandardError; end

  def self.[](operations:, adapter:, extension: Transaction::NULL_EXTENSION)
    TransactionWrapper.new(operations:, adapter:, extension:)
  end

  # Wraps a {Kwork::Transaction}
  class TransactionWrapper < Module
    # @api private
    def self.resolve_operations(operations, instance)
      operations.transform_values do |operation|
        operation.is_a?(Symbol) ? instance.method(operation) : operation
      end
    end

    # Instance methods to make available
    module InstanceMethods
      def initialize(operations: {})
        operations = TransactionWrapper.resolve_operations(
          self.class.instance_variable_get(:@_operations).merge(operations),
          self
        )
        @_transaction = Transaction.new(
          operations:,
          adapter: self.class.instance_variable_get(:@_adapter),
          extension: self.class.instance_variable_get(:@_extension)
        )
        super()
      end

      def transaction(&)
        @_transaction.transaction(&)
      end
    end

    include InstanceMethods

    # rubocop:disable Lint/MissingSuper
    def initialize(operations:, adapter:, extension:)
      @operations = operations
      @adapter = adapter
      @extension = extension
    end
    # rubocop:enable Lint/MissingSuper

    def included(klass)
      klass.instance_variable_set(:@_operations, @operations)
      klass.instance_variable_set(:@_adapter, @adapter)
      klass.instance_variable_set(:@_extension, @extension)
      klass.include(InstanceMethods)
    end
  end
end
