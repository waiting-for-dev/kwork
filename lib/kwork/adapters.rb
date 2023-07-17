# frozen_string_literal: true

module Kwork
  # Result adapters
  #
  # Kwork can work with different result types, as long as an adapter is
  # provided.
  #
  # A valid adapter is an interface implementing two methods:
  #
  # - `.from_kwork_result(result)` - converts a {Kwork::Result} to the adapter
  #  type.
  # - `.to_kwork_result(result)` - converts the adapter type to a
  #  {Kwork::Result}.
  module Adapters
    # @api private
    # rubocop:disable Naming/MethodName
    def self.Type(value, registry)
      case value
      when Symbol
        registry.fetch(value)
      else
        value
      end
    end
    # rubocop:enable Naming/MethodName
  end
end
