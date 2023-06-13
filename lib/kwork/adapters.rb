# frozen_string_literal: true

module Kwork
  module Adapters
    # @api private
    def self.Type(value, registry)
      case value
      when Symbol
        registry.fetch(value)
      else
        value
      end
    end
  end
end
