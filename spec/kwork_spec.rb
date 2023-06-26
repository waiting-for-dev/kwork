# frozen_string_literal: true

require "kwork"
require "kwork/result"
require "dry/monads/result"

RSpec.describe Kwork do
  it "has a version number" do
    expect(Kwork::VERSION).not_to be(nil)
  end

  context "when included" do
    it "transparently delegates to a transaction instance" do
      klass = Class.new do
        include Kwork[
          operations: {
            add_one: ->(x) { Kwork::Result.pure(x + 1) },
            add_two: ->(x) { Kwork::Result.pure(x + 2) }
          }
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
            add_one: ->(x) { Kwork::Result.pure(x + 1) },
            add_two: ->(x) { Kwork::Result.pure(x + 2) }
          }
        ]

        def call
          transaction do |r|
            x = r.add_one(1)
            r.add_two(x)
          end
        end
      end
      add_three = ->(x) { Kwork::Result.pure(x + 3) }

      klass.new(operations: { add_two: add_three }).() => [value]

      expect(value).to be(5)
    end

    it "can use own methods as operations when given as symbols" do
      klass = Class.new do
        include Kwork[
          operations: {
            add_one: :add_one,
            add_two: ->(x) { Kwork::Result.pure(x + 2) }
          }
        ]

        def call
          transaction do |r|
            x = r.add_one(1)
            r.add_two(x)
          end
        end

        private

        def add_one(value)
          Kwork::Result.pure(value + 1)
        end
      end

      klass.new.() => [value]

      expect(value).to be(4)
    end

    it "can take all operations from methods when given as an array of symbols" do
      klass = Class.new do
        include Kwork[
          operations: %i[add_one add_two]
        ]

        def call
          transaction do |r|
            x = r.add_one(1)
            r.add_two(x)
          end
        end

        private

        def add_one(value)
          Kwork::Result.pure(value + 1)
        end

        def add_two(value)
          Kwork::Result.pure(value + 2)
        end
      end

      klass.new.() => [value]

      expect(value).to be(4)
    end

    it "can take the adapter as a symbol" do
      klass = Class.new do
        include Kwork[
          operations: {
            add_one: ->(x) { Dry::Monads::Result.pure(x + 1) },
            add_two: ->(x) { Dry::Monads::Result.pure(x + 2) }
          },
          adapter: :result
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

    it "can take the extension as a symbol" do
      klass = Class.new do
        include Kwork[
          operations: {
            add_one: ->(x) { Kwork::Result.pure(x + 1) },
            add_two: ->(x) { Kwork::Result.pure(x + 2) }
          },
          extension: :active_record
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

    describe "#success" do
      it "wraps in a success result" do
        klass = Class.new do
          include Kwork[
            operations: {},
            adapter: Kwork::Adapters::DryMonads::Result
          ]
        end

        expect(klass.new.success(1)).to eq(Dry::Monads::Result.pure(1))
      end
    end

    describe "#failure" do
      it "wraps in a failure result" do
        klass = Class.new do
          include Kwork[
            operations: {},
            adapter: Kwork::Adapters::DryMonads::Result
          ]
        end

        expect(klass.new.failure(1)).to eq(Dry::Monads::Result::Failure.new(1))
      end
    end
  end
end
