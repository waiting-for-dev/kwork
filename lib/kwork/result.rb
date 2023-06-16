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

      def failure!
        raise <<~MSG
          There's no failure wrapped within a Kwork::Result::Success instance.
          Do you want to call `#value!` instead?
        MSG
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

      def value!
        raise <<~MSG
          There's no value wrapped within a Kwork::Result::Failure instance
          Do you want to call `#failure!` instead?
        MSG
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
