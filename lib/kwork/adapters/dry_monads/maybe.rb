# frozen_string_literal: true

begin
  require "dry/monads"
rescue LoadError
  raise "Please add dry-monads gem to your Gemfile to use Kwork::Adapters::DryMonads::Maybe"
end
require "kwork/result"

module Kwork
  module Adapters
    module DryMonads
      # Adapter for Dry::Monads::Maybe
      #
      # @see {Kwork::Adapters}
      # @see https://dry-rb.org/gems/dry-monads/1.6/maybe/
      module Maybe
        # @api private
        def self.from_kwork_result(result)
          case result
          in ::Kwork::Result::Success(value)
            Dry::Monads::Maybe.pure(value)
          in ::Kwork::Result::Failure
            Dry::Monads::Maybe::None.new
          end
        end

        # @api private
        def self.to_kwork_result(result)
          case result
          in Dry::Monads::Maybe::Some[value]
            ::Kwork::Result.pure(value)
          in Dry::Monads::Maybe::None
            ::Kwork::Result::Failure.new(nil)
          end
        end
      end
    end
  end
end
