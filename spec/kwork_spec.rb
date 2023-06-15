# frozen_string_literal: true

require "kwork"
require "kwork/result"

RSpec.describe Kwork do
  it "has a version number" do
    expect(Kwork::VERSION).not_to be(nil)
  end

  context "when included" do
    it "transparently works with a transaction instance" do
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

    it "can use own methods as operations" do
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

    it "can use a list of symbols as operations when all of them reference methods" do
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
end
