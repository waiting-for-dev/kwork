# frozen_string_literal: true

require "kwork/adapters/dry_monads/maybe"
require "kwork/adapters/dry_monads/result"
require "kwork/adapters/result"

module Kwork
  # @api private
  module Adapters
    class Registry
      DEFAULTS = {
        result: DryMonads::Result,
        maybe: DryMonads::Maybe,
        kwork: Result
      }.freeze

      def initialize
        @registry = DEFAULTS.dup
      end

      def register(shortcut, adapter)
        @registry[shortcut] = adapter
      end

      def fetch(shortcut)
        @registry.fetch(shortcut) do
          raise KeyError, <<~MSG
            Adapter #{shortcut} is not known.

            Known adapters are: #{@registry.keys.map(&:inspect).join(', ')}
          MSG
        end
      end
    end
  end
end
