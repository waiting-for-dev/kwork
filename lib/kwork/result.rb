# frozen_string_literal: true

module Kwork
  # Default result type
  #
  # There can be two types of results:
  #
  # - {Kwork::Result::Success} - when the operation was successful
  # - {Kwork::Result::Failure} - when the operation failed
  class Result
    # @param value [Object] the value to wrap
    # @return [Kwork::Result::Success]
    def self.pure(value)
      Success.new(value)
    end

    # A successful result
    class Success < Result
      # @api private
      def initialize(value)
        @value = value
        super()
      end

      # @return [true]
      def success?
        true
      end

      # @return [false]
      def failure?
        false
      end

      # @return [Object] the wrapped value
      def value!
        @value
      end

      # @raise [RuntimeError]
      def failure!
        raise <<~MSG
          There's no failure wrapped within a Kwork::Result::Success instance.
          Do you want to call `#value!` instead?
        MSG
      end

      # @return [Object] the wrapped value
      def value_or(_value)
        @value
      end

      # Yield the wrapped value to a block
      #
      # This is usually used to chain operations returning another result
      # together.
      #
      # @example
      #   Kwork::Result.pure(1).bind do |value|
      #     Kwork::Result.pure(value + 1)
      #   end ## => Kwork::Result.pure(2)
      #
      # @yieldparam value [Object] the wrapped value
      def bind
        yield @value
      end

      # Return a new result with the wrapped value transformed by a block
      #
      # @example
      #   Kwork::Result.pure(1).map do |value|
      #     value + 1
      #   end ## => Kwork::Result.pure(2)
      #
      # @yieldparam value [Object] the wrapped value
      def map
        self.class.new(yield @value)
      end

      # Applies first proc to the wrapped value
      #
      # @param f [#call] the proc to apply
      def either(f, _g)
        f.(@value)
      end

      # @param other [Object]
      # @return [Boolean] wheter other object is a {Kwork::Result::Success} with
      # the same wrapped value
      def ==(other)
        self.class === other &&
          other.instance_variable_get(:@value) == @value
      end
      alias eql? ==

      # @return [Array] array with the wrapped value
      def deconstruct
        [value!]
      end
    end

    # A failed result
    class Failure < Result
      # @param failure [Object] the failure to wrap
      def initialize(failure)
        @failure = failure
        super()
      end

      # @return [false]
      def success?
        false
      end

      # @return [true]
      def failure?
        true
      end

      # @raise [RuntimeError]
      def value!
        raise <<~MSG
          There's no value wrapped within a Kwork::Result::Failure instance
          Do you want to call `#failure!` instead?
        MSG
      end

      # @return [Object] the wrapped failure
      def failure!
        @failure
      end

      # @param value [Object] the value to return
      def value_or(value)
        value
      end

      # Short-circuits the chain of operations
      #
      # This is usually used to chain operations returning another result
      # together.
      #
      # @example
      #  Kwork::Result.failure(1).bind do |value|
      #    Kwork::Result.pure(value + 1)
      #  end # => Kwork::Result.failure(1)
      #
      # @return [Kwork::Result::Failure] itself
      def bind
        itself
      end

      # @return [Kwork::Result::Failure] itself
      def map
        itself
      end

      # Applies second proc to the wrapped failure
      #
      # @param g [#call] the proc to apply
      def either(_f, g)
        g.(@failure)
      end

      # @param other [Object]
      # @return [Boolean] wheter other object is a {Kwork::Result::Failure} with
      # the same wrapped failure
      def ==(other)
        self.class === other &&
          other.instance_variable_get(:@failure) == @failure
      end
      alias eql? ==

      # @return [Array] array with the wrapped failure
      def deconstruct
        [@failure]
      end
    end
  end
end
