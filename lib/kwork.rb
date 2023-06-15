# frozen_string_literal: true

require_relative "kwork/adapters"
require_relative "kwork/adapters/registry"
require_relative "kwork/adapters/kwork"
require_relative "kwork/resolver"
require_relative "kwork/transaction"
require_relative "kwork/version"

# DSL usage for a {Kwork::Transaction}
module Kwork
  class Error < StandardError; end

  def self.[](
    operations:,
    adapter: Adapters::Kwork,
    extension: Transaction::NULL_EXTENSION,
    resolver: Resolver,
    registry: Adapters::Registry.new
  )
    TransactionWrapper.new(operations:, adapter:, extension:, resolver:, registry:)
  end

  # Wraps a {Kwork::Transaction}
  class TransactionWrapper < Module
    # Instance methods to make available
    module InstanceMethods
      def initialize(operations: {})
        dsl_operations = self.class.instance_variable_get(:@_resolver).(
          operations: self.class.instance_variable_get(:@_operations),
          instance: self
        )
        @_transaction = Transaction.new(
          operations: dsl_operations,
          adapter: self.class.instance_variable_get(:@_adapter),
          extension: self.class.instance_variable_get(:@_extension)
        ).merge_operations(**operations)
        super()
      end

      def transaction(&)
        @_transaction.transaction(&)
      end
    end

    include InstanceMethods

    # rubocop:disable Lint/MissingSuper
    def initialize(operations:, adapter:, extension:, resolver:, registry:)
      @operations = operations
      @registry = registry
      @adapter = Adapters.Type(adapter, @registry)
      @extension = extension
      @resolver = resolver
    end
    # rubocop:enable Lint/MissingSuper

    def included(klass)
      klass.instance_variable_set(:@_operations, @operations)
      klass.instance_variable_set(:@_adapter, @adapter)
      klass.instance_variable_set(:@_extension, @extension)
      klass.instance_variable_set(:@_resolver, @resolver)
      klass.instance_variable_set(:@_registry, @registry)
      klass.include(InstanceMethods)
    end
  end
end
