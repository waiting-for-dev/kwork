# frozen_string_literal: true

begin
  require "dry/monads"
rescue LoadError
  raise "Please add dry-monads gem to your Gemfile to use Kwork::Adapter::DryMonads::Result"
end

module Kwork
  module Adapter
    module DryMonads
      # Adapter for Dry::Monads::Result
      module Result
        def self.wrap(value)
          Dry::Monads::Result.pure(value)
        end

        def self.fail(value)
          Dry::Monads::Result::Failure.new(value)
        end

        def self.unwrap(result)
          result.value!
        end

        def self.unwrap_failure(result)
          result.failure
        end

        def self.success?(result)
          result.success?
        end
      end
    end
  end
end
