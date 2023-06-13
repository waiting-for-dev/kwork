# frozen_string_literal: true

require "kwork/adapters/result"
require "kwork/adapters/dry_monads/result"
require "kwork/adapters/dry_monads/maybe"
require "kwork/transaction"
require "spec_helper"

RSpec.describe Kwork::Transaction do
  [Kwork::Adapters::Result, Kwork::Adapters::DryMonads::Result, Kwork::Adapters::DryMonads::Maybe].each do |adapter|
    describe "#transaction" do
      it "chains operations" do
        instance = described_class.new(
          operations: {
            add_one: ->(x) { adapter.wrap_success(x + 1) },
            add_two: ->(x) { adapter.wrap_success(x + 2) }
          },
          adapter:
        )

        instance.transaction do |r|
          x = r.add_one(1)
          r.add_two(x)
        end => [value]

        expect(value).to be(4)
      end

      it "stops chaining on failure" do
        instance = described_class.new(
          operations: {
            add_one: ->(_x) { adapter.wrap_failure(:error) },
            add_two: ->(x) { adapter.wrap_success(x + 2) }
          },
          adapter:
        )

        result = instance.transaction do |r|
          r.add_one(1)
          raise "error"
        end

        expect(result).to be_a(adapter.failure)
      end

      it "can intersperse operations that doesn't return a result" do
        instance = described_class.new(
          operations: {
            add_one: ->(x) { adapter.wrap_success(x + 1) },
            add_two: ->(x) { adapter.wrap_success(x + 2) }
          },
          adapter:
        )

        instance.transaction do |r|
          x = r.add_one(1)
          y = x + 1
          r.add_two(y)
        end => [value]

        expect(value).to be(5)
      end

      it "accepts anything responding to call as operation" do
        instance = described_class.new(
          operations: {
            add_one: ->(x) { adapter.wrap_success(x + 1) }.method(:call)
          },
          adapter:
        )

        instance.transaction do |r|
          r.add_one(1)
        end => [value]

        expect(value).to be(2)
      end

      it "wraps with provided extension" do
        extension = Class.new do
          attr_reader :value

          def initialize
            @value = nil
          end

          def call
            yield => [value]
            @value = value
          end
        end.new

        instance = described_class.new(
          operations: {
            add_one: ->(x) { adapter.wrap_success(x + 1) },
            add_two: ->(x) { adapter.wrap_success(x + 2) }
          },
          extension:,
          adapter:
        )

        instance.transaction do |r|
          x = r.add_one(1)
          r.add_two(x)
        end => [value]

        aggregate_failures do
          expect(extension.value).to be(4)
          expect(value).to be(4)
        end
      end
    end

    describe "#with" do
      it "returns new instance" do
        instance = described_class.new(
          operations: {
            add: ->(x) { adapter.wrap_success(x + 1) }
          },
          adapter:
        )

        new_instance = instance.with(add: -> {})

        expect(instance).not_to be(new_instance)
      end

      it "replaces operations" do
        instance = described_class.new(
          operations: {
            add: ->(x) { success(x + 1) }
          },
          adapter:
        )

        new_instance = instance.with(add: ->(x) { adapter.wrap_success(x + 2) })

        new_instance.transaction do |r|
          r.add(1)
        end => [value]
        expect(value).to be(3)
      end
    end
  end
end
