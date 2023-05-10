# frozen_string_literal: true

module Kwork
  # Simple result monad
  class Result
    def self.pure(value)
      Success.new(value)
    end

    # Right
    class Success < Result
      def initialize(value)
        @value = value
        super()
      end

      def success?
        true
      end

      def failure?
        false
      end

      def value!
        @value
      end

      def deconstruct
        [value!]
      end
    end

    # Left
    class Failure < Result
      def initialize(error)
        @error = error
        super()
      end

      def success?
        false
      end

      def failure?
        true
      end

      def error!
        @error
      end

      def deconstruct
        [@error]
      end
    end
  end
end
