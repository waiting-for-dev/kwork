# frozen_string_literal: true

require_relative "kwork/adapters"
require_relative "kwork/adapters/registry"
require_relative "kwork/adapters/kwork"
require_relative "kwork/transaction"
require_relative "kwork/version"

# DSL usage for a {Kwork::Transaction}
#
# Including this module brings a transaction instance and keeps it under the
# hood. A `#transaction` instance method is made available to run the passed
# operations. A couple of `#success` and `#failure` methods are also available
# to wrap within the configured result adapter.
module Kwork
  class Error < StandardError; end

  def self.included(klass)
    klass.include(self.[])
  end

  # @param adapter see {Kwork::Transaction#initialize}
  # @param extension see {Kwork::Transaction#initialize}
  # @param profiler see {Kwork::Transaction#initialize}
  #
  def self.[](
    adapter: Adapters::Kwork,
    extension: Transaction::NULL_EXTENSION,
    profiler: Transaction::NULL_PROFILER,
    adapter_registry: Adapters::Registry.new
  )
    TransactionWrapper.new(adapter:, extension:, adapter_registry:, profiler:)
  end

  # @api private
  class TransactionWrapper < Module
    # Instance methods to make available
    module InstanceMethods
      def initialize
        adapter = self.class.instance_variable_get(:@_adapter)
        extension = self.class.instance_variable_get(:@_extension)
        profiler = self.class.instance_variable_get(:@_profiler)
        @_transaction = Transaction.new(
          adapter:,
          extension:,
          profiler:,
          runner: Runner.new(instance: self, adapter:, profiler:)
        )
        super()
      end

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

    # rubocop:disable Lint/MissingSuper
    def initialize(adapter:, extension:, adapter_registry:, profiler:)
      @adapter_registry = adapter_registry
      @adapter = Adapters.Type(adapter, @adapter_registry)
      @extension = extension
      @profiler = profiler
    end
    # rubocop:enable Lint/MissingSuper

    def included(klass)
      klass.instance_variable_set(:@_adapter, @adapter)
      klass.instance_variable_set(:@_extension, @extension)
      klass.instance_variable_set(:@_adapter_registry, @adapter_registry)
      klass.instance_variable_set(:@_profiler, @profiler)
      klass.include(InstanceMethods)
    end
  end
end
