# frozen_string_literal: true

require "kwork/adapters/registry"
require "kwork/result"
require "kwork/transaction"
require "spec_helper"

RSpec.describe Kwork::Transaction do
  shared_examples "transaction" do |adapter|
    context "with #{adapter} adapter" do
      describe "#transaction" do
        it "chains successful operations, unwrapping intermediate results" do
          instance = Class.new(described_class) do
            def call
              transaction do
                x = step add_one(1)
                step add_two(x)
              end
            end

            def add_one(x)
              @adapter.from_kwork_result(Kwork::Result.pure(x + 1))
            end

            def add_two(x)
              @adapter.from_kwork_result(Kwork::Result.pure(x + 2))
            end
          end.new(adapter:)

          instance.() => [value]

          expect(value).to be(4)
        end

        it "stops chaining on failure, returning last result" do
          instance = Class.new(described_class) do
            def call
              transaction do
                step add_one(1)
                raise "error"
              end
            end

            def add_one(_x)
              @adapter.from_kwork_result(Kwork::Result::Failure.new(:failure))
            end

            def add_two(x)
              @adapter.from_kwork_result(Kwork::Result.pure(x + 2))
            end
          end.new(adapter:)

          result = instance.()

          expect(adapter.to_kwork_result(result)).to be_a(Kwork::Result::Failure)
        end

        it "doesn't require all calls within the block to return a result" do
          instance = Class.new(described_class) do
            def call
              transaction do
                x = step add_one(1)
                y = x + 1
                step add_two(y)
              end
            end

            def add_one(x)
              @adapter.from_kwork_result(Kwork::Result.pure(x + 1))
            end

            def add_two(x)
              @adapter.from_kwork_result(Kwork::Result.pure(x + 2))
            end
          end.new(adapter:)

          instance.() => [value]

          expect(value).to be(5)
        end

        it "wraps with provided extension" do
          extension = Class.new do
            def call(callback)
              callback.() => [value]
              Kwork::Result.pure(value + 1)
            end
          end.new

          instance = Class.new(described_class) do
            def call
              transaction do
                x = step add_one(1)
                step add_two(x)
              end
            end

            def add_one(x)
              @adapter.from_kwork_result(Kwork::Result.pure(x + 1))
            end

            def add_two(x)
              @adapter.from_kwork_result(Kwork::Result.pure(x + 2))
            end
          end.new(adapter:, extension:)

          instance.() => [value]

          expect(value).to be(5)
        end
      end
    end
  end

  Kwork::Adapters::Registry.new.adapters.each do |adapter|
    include_examples "transaction", adapter
  end

  describe "#step" do
    it "returns wrapped value" do
      expect(
        described_class.new.step(Kwork::Result.pure(2))
      ).to be(2)
    end

    it "throws :halt with the failure" do
      failure = Kwork::Result::Failure.new(:foo)

      expect {
        described_class.new.step(failure)
      }.to throw_symbol(:halt, failure)
    end
  end
end
