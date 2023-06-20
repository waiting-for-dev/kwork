# frozen_string_literal: true

require "kwork/extensions/active_record"

module Kwork
  # @api private
  module Extensions
    # Extensions registry
    class Registry
      DEFAULTS = {
        active_record: ActiveRecord
      }.freeze

      def initialize
        @registry = DEFAULTS.dup
      end

      def register(shortcut, extension)
        @registry[shortcut] = extension
      end

      def fetch(shortcut)
        @registry.fetch(shortcut) do
          raise KeyError, <<~MSG
            Extension #{shortcut} is not known.

            Known extensions are: #{@registry.keys.map(&:inspect).join(", ")}
          MSG
        end
      end
    end
  end
end
