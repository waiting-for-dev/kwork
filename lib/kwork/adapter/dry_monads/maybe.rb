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
        def self.wrap(value)
          Dry::Monads::Maybe.pure(value)
        end

        def self.fail(_value)
          Dry::Monads::Maybe::None.new
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
end
