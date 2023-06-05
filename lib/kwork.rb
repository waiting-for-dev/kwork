# frozen_string_literal: true

require_relative "kwork/version"
require_relative "kwork/resolver"
require_relative "kwork/transaction"

# DSL usage for a {Kwork::Transaction}
module Kwork
  class Error < StandardError; end

  def self.[](operations:, adapter:, extension: Transaction::NULL_EXTENSION, resolver: Resolver)
    TransactionWrapper.new(operations:, adapter:, extension:, resolver:)
  end

  # Wraps a {Kwork::Transaction}
  class TransactionWrapper < Module
    # Instance methods to make available
    module InstanceMethods
      def initialize(operations: {})
        operations = self.class.instance_variable_get(:@_resolver).(
          operations: self.class.instance_variable_get(:@_operations),
          instance: self
        ).merge(operations)
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
    def initialize(operations:, adapter:, extension:, resolver:)
      @operations = operations
      @adapter = adapter
      @extension = extension
      @resolver = resolver
    end
    # rubocop:enable Lint/MissingSuper

    def included(klass)
      klass.instance_variable_set(:@_operations, @operations)
      klass.instance_variable_set(:@_adapter, @adapter)
      klass.instance_variable_set(:@_extension, @extension)
      klass.instance_variable_set(:@_resolver, @resolver)
      klass.include(InstanceMethods)
    end
  end
end
