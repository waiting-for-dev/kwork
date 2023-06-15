# frozen_string_literal: true

module Kwork
  # Result adapters
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