# frozen_string_literal: true

require_relative "kwork/adapters"
require_relative "kwork/adapters/registry"
require_relative "kwork/adapters/kwork"
require_relative "kwork/extensions"
require_relative "kwork/extensions/registry"
require_relative "kwork/resolver"
require_relative "kwork/transaction"
require_relative "kwork/version"

# DSL usage for a {Kwork::Transaction}
module Kwork
  class Error < StandardError; end

  # rubocop:disable Metrics/ParameterLists
  def self.[](
    operations:,
    adapter: Adapters::Kwork,
    extension: Transaction::NULL_EXTENSION,
    resolver: Resolver,
    adapter_registry: Adapters::Registry.new,
    extension_registry: Extensions::Registry.new
  )
    TransactionWrapper.new(operations:, adapter:, extension:, resolver:, adapter_registry:, extension_registry:)
  end
  # rubocop:enable Metrics/ParameterLists

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
    # rubocop:disable Metrics/ParameterLists
    def initialize(operations:, adapter:, extension:, resolver:, adapter_registry:, extension_registry:)
      @operations = operations
      @adapter_registry = adapter_registry
      @adapter = Adapters.Type(adapter, @adapter_registry)
      @extension_registry = extension_registry
      @extension = Extensions.Type(extension, @extension_registry)
      @resolver = resolver
    end
    # rubocop:enable Lint/MissingSuper
    # rubocop:enable Metrics/ParameterLists

    def included(klass)
      klass.instance_variable_set(:@_operations, @operations)
      klass.instance_variable_set(:@_adapter, @adapter)
      klass.instance_variable_set(:@_extension, @extension)
      klass.instance_variable_set(:@_resolver, @resolver)
      klass.instance_variable_set(:@_adapter_registry, @adapter_registry)
      klass.instance_variable_set(:@_extension_registry, @extension_registry)
      klass.include(InstanceMethods)
    end
  end
end
