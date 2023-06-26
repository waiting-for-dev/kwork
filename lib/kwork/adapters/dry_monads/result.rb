# frozen_string_literal: true

begin
  require "dry/monads"
rescue LoadError
  raise "Please add dry-monads gem to your Gemfile to use Kwork::Adapters::DryMonads::Result"
end
require "kwork/result"

module Kwork
  module Adapters
    module DryMonads
      # Adapter for Dry::Monads::Result
      module Result
        def self.from_kwork_result(result)
          case result
          in ::Kwork::Result::Success[value]
            Dry::Monads::Result.pure(value)
          in ::Kwork::Result::Failure[value]
            Dry::Monads::Result::Failure.new(value)
          end
        end

        def self.to_kwork_result(result)
          case result
          in Dry::Monads::Result::Success[value]
            ::Kwork::Result::Success.pure(value)
          in Dry::Monads::Result::Failure[value]
            ::Kwork::Result::Failure.new(value)
          end
        end
      end
    end
  end
end
