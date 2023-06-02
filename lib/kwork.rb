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
    # Instance methods to make available
    module InstanceMethods
      def initialize(operations: {})
        @_transaction = Transaction.new(
          operations: self.class.instance_variable_get(:@_operations).merge(operations),
          adapter: self.class.instance_variable_get(:@_adapter),
          extension: self.class.instance_variable_get(:@_extension)
        )
        super()
      end

      def transaction(&)
        @_transaction.transaction(&)
      end

      def runner
        @_transaction.runner
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
      klass.include(Transaction::MethodMissing)
      klass.include(InstanceMethods)
    end
  end
end
