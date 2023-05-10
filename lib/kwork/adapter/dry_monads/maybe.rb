# frozen_string_literal: true

begin
  require "dry/monads"
rescue LoadError
  raise "Please add dry-monads gem to your Gemfile to use Kwork::Adapter::DryMonads::Maybe"
end

module Kwork
  module Adapter
    module DryMonads
      # Adapter for Dry::Monads::Maybe
      module Maybe
        def self.success
          Dry::Monads::Maybe::Some
        end

        def self.failure
          Dry::Monads::Maybe::None
        end

        def self.wrap_success(value)
          Dry::Monads::Maybe.pure(value)
        end

        def self.wrap_failure(_)
          Dry::Monads::Maybe::None.new
        end
      end
    end
  end
end
