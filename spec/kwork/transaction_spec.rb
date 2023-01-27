# frozen_string_literal: true

require "kwork/adapter/result"
require "kwork/adapter/dry_monads/result"
require "kwork/adapter/dry_monads/maybe"
require "kwork/transaction"
require "spec_helper"

RSpec.describe Kwork::Transaction do
  [Kwork::Adapter::Result, Kwork::Adapter::DryMonads::Result, Kwork::Adapter::DryMonads::Maybe].each do |adapter|
    describe "#transaction" do
      it "chains operations" do
        instance = described_class.new(
          operations: {
            add_one: ->(x) { adapter.wrap(x + 1) },
            add_two: ->(x) { adapter.wrap(x + 2) }
          },
          adapter: adapter
        )

        result = instance.transaction do |e|
          x = e.add_one(1)
          e.add_two(x)
        end

        expect(
          adapter.unwrap(result)
        ).to be(4)
      end

      it "stops chaining on failure" do
        failure = adapter.fail(:error)
        instance = described_class.new(
          operations: {
            add_one: ->(_x) { failure },
            add_two: ->(x) { adapter.wrap(x + 2) }
          },
          adapter: adapter
        )

        result = instance.transaction do |e|
          e.add_one(1)
          raise "error"
        end

        expect(
          result
        ).to be(failure)
      end

      it "can intersperse operations that doesn't return a result" do
        instance = described_class.new(
          operations: {
            add_one: ->(x) { adapter.wrap(x + 1) },
            add_two: ->(x) { adapter.wrap(x + 2) }
          },
          adapter: adapter
        )

        result = instance.transaction do |e|
          x = e.add_one(1)
          y = x + 1
          e.add_two(y)
        end

        expect(
          adapter.unwrap(result)
        ).to be(5)
      end

      it "accepts anything responding to call as operation" do
        instance = described_class.new(
          operations: {
            add_one: ->(x) { adapter.wrap(x + 1) }.method(:call)
          },
          adapter: adapter
        )

        result = instance.transaction do |e|
          e.add_one(1)
        end

        expect(
          adapter.unwrap(result)
        ).to be(2)
      end

      it "wraps with provided extension" do
        extension = Class.new do
          attr_reader :adapter, :value

          def initialize(adapter:)
            @value = nil
            @adapter = adapter
          end

          def call
            result = yield

            @value = adapter.unwrap(result) if adapter.success?(result)
          end
        end.new(adapter: adapter)

        instance = described_class.new(
          operations: {
            add_one: ->(x) { adapter.wrap(x + 1) },
            add_two: ->(x) { adapter.wrap(x + 2) }
          },
          extension: extension,
          adapter: adapter
        )

        result = instance.transaction do |e|
          x = e.add_one(1)
          e.add_two(x)
        end

        aggregate_failures do
          expect(extension.value).to be(4)
          expect(adapter.unwrap(result)).to be(4)
        end
      end
    end

    describe "#with" do
      it "returns new instance" do
        instance = described_class.new(
          operations: {
            add: ->(x) { adapter.wrap(x + 1) }
          },
          adapter: adapter
        )

        new_instance = instance.with(add: -> {})

        expect(instance).not_to be(new_instance)
      end

      it "replaces operations" do
        instance = described_class.new(
          operations: {
            add: ->(x) { success(x + 1) }
          },
          adapter: adapter
        )

        new_instance = instance.with(add: ->(x) { adapter.wrap(x + 2) })

        result = new_instance.transaction do |e|
          e.add(1)
        end
        expect(
          adapter.unwrap(result)
        ).to be(3)
      end
    end

    describe ".with_delegation" do
      it "can delegate from the transaction instance" do
        klass = Class.new(described_class) do
          def call
            transaction do
              two = add_one(1)
              add_two(two)
            end
          end
        end
        klass.with_delegation
        instance = klass.new(
          operations: {
            add_one: ->(x) { adapter.wrap(x + 1) },
            add_two: ->(x) { adapter.wrap(x + 2) }
          },
          adapter: adapter
        )

        result = instance.()
        expect(
          adapter.unwrap(result)
        ).to be(4)
      end
    end
  end
end
