# frozen_string_literal: true

begin
  require "dry/monads"
rescue LoadError
  raise "Please add dry-monads gem to your Gemfile to use Kwork::Adapters::DryMonads::Result"
end

module Kwork
  module Adapters
    module DryMonads
      # Adapter for Dry::Monads::Result
      module Result
        def self.success
          Dry::Monads::Result::Success
        end

        def self.failure
          Dry::Monads::Result::Failure
        end

        def self.wrap_success(value)
          Dry::Monads::Result.pure(value)
        end

        def self.wrap_failure(value)
          Dry::Monads::Result::Failure.new(value)
        end
      end
    end
  end
end
