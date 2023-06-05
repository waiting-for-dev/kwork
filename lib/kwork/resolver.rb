# frozen_string_literal: true

module Kwork
  # @api private
  module Resolver
    # rubocop:disable Metrics/MethodLength
    def self.call(operations:, instance:)
      case operations
      when Array
        resolve_operations_from_array(operations, instance)
      when Hash
        resolve_operations_from_hash(operations, instance)
      else
        raise ArgumentError, <<~MSG
          operations can be given as an Array or Hash:

          - Array: operations are resolved from instance methods
          - Hash: operations are resolved from the values of the hash, which can be either:
            - a Symbol, which is resolved from an instance method
            - a callable, which is used as-is

          #{operations.inspect} is not a valid operations specification
        MSG
      end
    end
    # rubocop:enable Metrics/MethodLength

    class << self
      private

      def resolve_operations_from_array(operations, instance)
        Hash[operations.map { [_1, resolve_operation_from_method(_1, instance)] }]
      end

      def resolve_operations_from_hash(operations, instance)
        operations.transform_values do |operation|
          if operation.is_a?(Symbol)
            resolve_operation_from_method(operation,
                                          instance)
          else
            resolve_operation_from_callable(operation)
          end
        end
      end

      def resolve_operation_from_method(operation, instance)
        instance.method(operation)
      end

      def resolve_operation_from_callable(operation)
        raise ArgumentError, <<~MSG unless operation.respond_to?(:call)
          operation must be given as either:

          - a Symbol, which is resolved from an instance method
          - a callable, which is used as-is
        MSG

        operation
      end
    end
  end
end
