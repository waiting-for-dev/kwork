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

  # rubocop:disable Metrics/ParameterLists
  def self.[](
    operations:,
    adapter: Adapters::Kwork,
    extension: Transaction::NULL_EXTENSION,
    profiler: Transaction::NULL_PROFILER,
    resolver: Resolver,
    adapter_registry: Adapters::Registry.new
  )
    TransactionWrapper.new(operations:, adapter:, extension:, resolver:, adapter_registry:, profiler:)
  end
  # rubocop:enable Metrics/ParameterLists

  # Wraps a {Kwork::Transaction}
  class TransactionWrapper < Module
    # Instance methods to make available
    module InstanceMethods
      # rubocop:disable Metrics/MethodLength
      def initialize(operations: {})
        dsl_operations = self.class.instance_variable_get(:@_resolver).(
          operations: self.class.instance_variable_get(:@_operations),
          instance: self
        )
        @_transaction = Transaction.new(
          operations: dsl_operations,
          adapter: self.class.instance_variable_get(:@_adapter),
          extension: self.class.instance_variable_get(:@_extension),
          profiler: self.class.instance_variable_get(:@_profiler)
        ).merge_operations(**operations)
        super()
      end
      # rubocop:enable Metrics/MethodLength

      def transaction(&)
        @_transaction.transaction(&)
      end

      def success(value)
        self.class.instance_variable_get(:@_adapter)
            .from_kwork_result(
              Kwork::Result.pure(value)
            )
      end

      def failure(value)
        self.class.instance_variable_get(:@_adapter)
            .from_kwork_result(
              Kwork::Result::Failure.new(value)
            )
      end
    end

    include InstanceMethods

    # rubocop:disable Metrics/ParameterLists
    # rubocop:disable Lint/MissingSuper
    def initialize(operations:, adapter:, extension:, resolver:, adapter_registry:, profiler:)
      @operations = operations
      @adapter_registry = adapter_registry
      @adapter = Adapters.Type(adapter, @adapter_registry)
      @extension = extension
      @profiler = profiler
      @resolver = resolver
    end
    # rubocop:enable Metrics/ParameterLists
    # rubocop:enable Lint/MissingSuper

    def included(klass)
      klass.instance_variable_set(:@_operations, @operations)
      klass.instance_variable_set(:@_adapter, @adapter)
      klass.instance_variable_set(:@_extension, @extension)
      klass.instance_variable_set(:@_resolver, @resolver)
      klass.instance_variable_set(:@_adapter_registry, @adapter_registry)
      klass.instance_variable_set(:@_profiler, @profiler)
      klass.include(InstanceMethods)
    end
  end
end
