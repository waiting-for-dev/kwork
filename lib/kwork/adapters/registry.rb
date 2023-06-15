# frozen_string_literal: true

require "kwork/adapters/dry_monads/maybe"
require "kwork/adapters/dry_monads/result"
require "kwork/adapters/kwork"

module Kwork
  # @api private
  module Adapters
    # Result types registry
    class Registry
      DEFAULTS = {
        result: DryMonads::Result,
        maybe: DryMonads::Maybe,
        kwork: Kwork
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

            Known adapters are: #{@registry.keys.map(&:inspect).join(", ")}
          MSG
        end
      end

      def adapters
        @registry.values
      end
    end
  end
end
