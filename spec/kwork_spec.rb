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
              add_one: ->(x) { adapter.wrap_success(x + 1) },
              add_two: ->(x) { adapter.wrap_success(x + 2) }
            },
            adapter:
          ]

          def call
            transaction do |r|
              x = r.add_one(1)
              r.add_two(x)
            end
          end
        end

        klass.new.() => [value]

        expect(value).to be(4)
      end

      it "can inject operations on initialization" do
        klass = Class.new do
          include Kwork[
            operations: {
              add_one: ->(x) { adapter.wrap_success(x + 1) },
              add_two: ->(x) { adapter.wrap_success(x + 2) }
            },
            adapter:
          ]

          def call
            transaction do |r|
              x = r.add_one(1)
              r.add_two(x)
            end
          end
        end
        add_three = ->(x) { adapter.wrap_success(x + 3) }

        klass.new(operations: { add_two: add_three }).() => [value]

        expect(value).to be(5)
      end

      it "can use own methods as operations" do
        klass = Class.new do
          include Kwork[
            operations: {
              add_one: :add_one,
              add_two: ->(x) { adapter.wrap_success(x + 2) }
            },
            adapter:
          ]

          def call
            transaction do |r|
              x = r.add_one(1)
              r.add_two(x)
            end
          end

          private

          def add_one(value)
            self.class.instance_variable_get(:@_adapter).wrap_success(value + 1)
          end
        end

        klass.new.() => [value]

        expect(value).to be(4)
      end

      it "can use a list of symbols as operations when all of them reference methods" do
        klass = Class.new do
          include Kwork[
            operations: %i[add_one add_two],
            adapter:
          ]

          def call
            transaction do |r|
              x = r.add_one(1)
              r.add_two(x)
            end
          end

          private

          def add_one(value)
            self.class.instance_variable_get(:@_adapter).wrap_success(value + 1)
          end

          def add_two(value)
            self.class.instance_variable_get(:@_adapter).wrap_success(value + 2)
          end
        end

        klass.new.() => [value]

        expect(value).to be(4)
      end
    end
  end
end
