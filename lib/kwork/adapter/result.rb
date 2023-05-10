# frozen_string_literal: true

require "kwork/result"

module Kwork
  module Adapter
    # Adapter for Kwork::Result
    module Result
      def self.success
        Kwork::Result::Success
      end

      def self.failure
        Kwork::Result::Failure
      end

      def self.wrap_success(value)
        Kwork::Result.pure(value)
      end

      def self.wrap_failure(value)
        Kwork::Result::Failure.new(value)
      end
    end
  end
end
