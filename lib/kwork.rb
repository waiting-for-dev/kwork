# frozen_string_literal: true

require_relative "kwork/version"
require_relative "kwork/transaction"

# DSL usage for a {Kwork::Transaction}
module Kwork
  class Error < StandardError; end

  def self.[](operations:, adapter:, extension: Transaction::NULL_EXTENSION)
    TransactionWrapper.new(operations: operations, adapter: adapter, extension: extension)
  end

  # Wraps a {Kwork::Transaction}
  class TransactionWrapper < Module
    # Instance methods to make available
    module InstanceMethods
      def transaction(&block)
        self.class.instance_variable_get(:@transaction).transaction(&block)
      end

      def operations
        self.class.instance_variable_get(:@transaction).operations
      end

      def executor
        self.class.instance_variable_get(:@transaction).executor
      end
    end

    include InstanceMethods

    # rubocop:disable Lint/MissingSuper
    def initialize(operations:, adapter:, extension:)
      @transaction = Transaction.new(operations:, adapter:, extension:)
    end
    # rubocop:enable Lint/MissingSuper

    def included(klass)
      klass.instance_variable_set(:@transaction, @transaction)
      klass.include(Transaction::MethodMissing)
      klass.include(InstanceMethods)
    end
  end
end
