# frozen_string_literal: true

require "kwork/result"

module Kwork
  module Adapter
    # Adapter for Kwork::Result
    module Result
      def self.wrap(value)
        Kwork::Result.pure(value)
      end

      def self.fail(value)
        Kwork::Result::Failure.new(value)
      end

      def self.unwrap(result)
        result.value!
      end

      def self.success?(result)
        result.success?
      end
    end
  end
end
