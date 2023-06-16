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
      def initialize(failure)
        @failure = failure
        super()
      end

      def success?
        false
      end

      def failure?
        true
      end

      def failure!
        @failure
      end

      def deconstruct
        [@failure]
      end
    end
  end
end
