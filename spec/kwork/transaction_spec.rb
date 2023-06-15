# frozen_string_literal: true

require "kwork/adapters/registry"
require "kwork/transaction"
require "spec_helper"

RSpec.describe Kwork::Transaction do
  shared_examples "transaction" do |adapter|
    context "with #{adapter} adapter" do
      describe "#transaction" do
        it "chains successful operations, unwrapping intermediate results" do
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

        it "stops chaining on failure, returning last result" do
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

        it "doesn't require all calls within the block to return a result" do
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
        it "returns a new instance" do
          instance = described_class.new(
            operations: {
              add: ->(x) { adapter.wrap_success(x + 1) }
            },
            adapter:
          )

          new_instance = instance.with(add: -> {})

          expect(instance).not_to be(new_instance)
        end

        it "replaces with given operations" do
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

        it "keeps the adapter" do
          instance = described_class.new(
            operations: {
              add: ->(x) { success(x + 1) }
            },
            adapter: Object
          )

          new_instance = instance.with(add: ->(x) { adapter.wrap_success(x + 2) })

          expect(new_instance.runner.adapter).to be(Object)
        end

        it "keeps the extension" do
          instance = described_class.new(
            operations: {
              add: ->(x) { success(x + 1) }
            },
            adapter:,
            extension: Object
          )

          new_instance = instance.with(add: ->(x) { adapter.wrap_success(x + 2) })

          expect(new_instance.extension).to be(Object)
        end
      end
    end
  end

  Kwork::Adapters::Registry.new.adapters.each do |adapter|
    include_examples "transaction", adapter
  end
end
