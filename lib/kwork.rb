# frozen_string_literal: true

require_relative "kwork/adapters"
require_relative "kwork/adapters/registry"
require_relative "kwork/adapters/kwork"
require_relative "kwork/resolver"
require_relative "kwork/transaction"
require_relative "kwork/version"

# DSL usage for a {Kwork::Transaction}
#
# Including this module brings a transaction instance and keeps it under the
# hood. A `#transaction` instance method is made available to run the configured
# operations. A couple of `#success` and `#failure` methods are also available
# to wrap within the configured result adapter.
module Kwork
  class Error < StandardError; end

  # @param operations {Symbol => [#call, Symbol}, Array<Symbol>] Map of names and
  #   callables returning a result type. If a {Symbol} is given instead of a
  #   callable, that's taken as an instance method from the including class. If,
  #   instead of an explicit map, a list of {Symbol} is given, all of them are
  #   taken as instance methods from the including class and the method name is
  #   used to identify them.
  # @param adapter see {Kwork::Transaction#initialize}
  # @param extension see {Kwork::Transaction#initialize}
  # @param profiler see {Kwork::Transaction#initialize}
  # @param resolver [#call] callable taking the declaration of operations and
  #   returning a Hash of {Symbol} and callables for the resolved operations.
  #
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

  # @api private
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

      # see {Kwork::Transaction#transaction}
      def transaction(&)
        @_transaction.transaction(&)
      end

      # Wraps a value in the success type for the used result adapter
      #
      # @param value [Object]
      # @return [Object]
      def success(value)
        self.class.instance_variable_get(:@_adapter)
            .from_kwork_result(
              Kwork::Result.pure(value)
            )
      end

      # Wraps a value in the failure type for the used result adapter
      #
      # @param value [Object]
      # @return [Object]
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
