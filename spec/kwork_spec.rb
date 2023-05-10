# frozen_string_literal: true

require "kwork/adapter/result"
require "kwork/adapter/dry_monads/result"
require "kwork/adapter/dry_monads/maybe"

RSpec.describe Kwork do
  it "has a version number" do
    expect(Kwork::VERSION).not_to be(nil)
  end

  context "when included" do
    [Kwork::Adapter::Result, Kwork::Adapter::DryMonads::Result, Kwork::Adapter::DryMonads::Maybe].each do |adapter|
      it "transparently works with a transaction instance" do
        klass = Class.new do
          include Kwork[
            operations: {
              add_one: ->(x) { adapter.wrap(x + 1) },
              add_two: ->(x) { adapter.wrap(x + 2) }
            },
            adapter: adapter
          ]

          def call
            transaction do |e|
              x = e.add_one(1)
              e.add_two(x)
            end
          end
        end

        result = klass.new.()

        expect(
          adapter.unwrap(result)
        ).to be(4)
      end

      it "delegates from the instance" do
        klass = Class.new do
          include Kwork[
            operations: {
              add_one: ->(x) { adapter.wrap(x + 1) },
              add_two: ->(x) { adapter.wrap(x + 2) }
            },
            adapter: adapter
          ]

          def call
            transaction do
              x = add_one(1)
              add_two(x)
            end
          end
        end

        result = klass.new.()

        expect(
          adapter.unwrap(result)
        ).to be(4)
      end
    end
  end
end
