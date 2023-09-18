# frozen_string_literal: true

require "kwork"
require "kwork/extensions/active_record"
require "kwork/result"
require "dry/monads/result"

RSpec.describe Kwork do
  it "has a version number" do
    expect(Kwork::VERSION).not_to be(nil)
  end

  context "when included" do
    it "transparently delegates to a transaction instance" do
      klass = Class.new do
        include Kwork

        def call
          x = step add_one(1)
          step add_two(x)
        end

        def add_one(x)
          Kwork::Result.pure(x + 1)
        end

        def add_two(x)
          Kwork::Result.pure(x + 2)
        end
      end

      klass.new.() => [value]

      expect(value).to be(4)
    end

    it "can take the adapter as a symbol" do
      klass = Class.new do
        include Kwork[
          adapter: :result
        ]

        def call
          x = step add_one(1)
          step add_two(x)
        end

        def add_one(x)
          Dry::Monads::Result.pure(x + 1)
        end

        def add_two(x)
          Dry::Monads::Result.pure(x + 2)
        end
      end

      klass.new.() => [value]

      expect(value).to be(4)
    end

    it "can specify extension" do
      run = false
      klass = Class.new do
        include Kwork[
          extension: lambda { |callback|
                       run = true
                       callback.()
                     }
        ]

        def call
          x = step add_one(1)
          step add_two(x)
        end

        def add_one(x)
          Kwork::Result.pure(x + 1)
        end

        def add_two(x)
          Kwork::Result.pure(x + 2)
        end
      end

      klass.new.() => [value]

      aggregate_failures do
        expect(value).to be(4)
        expect(run).to be(true)
      end
    end

    it "can pass arguments to call" do
      klass = Class.new do
        include Kwork

        def call(x)
          y = step add_one(x)
          step add_two(y)
        end

        def add_one(x)
          Kwork::Result.pure(x + 1)
        end

        def add_two(x)
          Kwork::Result.pure(x + 2)
        end
      end

      klass.new.(1) => [value]

      expect(value).to be(4)
    end

    describe "#success" do
      it "wraps in a success result" do
        klass = Class.new do
          include Kwork[
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
            adapter: Kwork::Adapters::DryMonads::Result
          ]
        end

        expect(klass.new.failure(1)).to eq(Dry::Monads::Result::Failure.new(1))
      end
    end
  end
end
