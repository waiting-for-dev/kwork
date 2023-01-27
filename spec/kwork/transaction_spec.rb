# frozen_string_literal: true

require "kwork/result"
require "kwork/transaction"
require "spec_helper"

RSpec.describe Kwork::Transaction do
  def success(value)
    Kwork::Result.pure(value)
  end

  def failure(value)
    Kwork::Result::Failure.new(value)
  end

  describe "#transaction" do
    it "chains operations" do
      instance = described_class.new(operations: {
        add_one: ->(x) { success(x + 1) },
        add_two: ->(x) { success(x + 2) }
      })

      result = instance.transaction do |e|
        x = e.add_one(1)
        e.add_two(x)
      end

      expect(result.value!).to be(4)
    end

    it "stops chaining on failure" do
      instance = described_class.new(operations: {
        add_one: ->(_x) { failure(:error) },
        add_two: ->(x) { success(x + 2) }
      })

      result = instance.transaction do |e|
        e.add_one(1)
        raise "error"
      end

      expect(result.error!).to be(:error)
    end

    it "can intersperse operations that doesn't return a result" do
      instance = described_class.new(operations: {
        add_one: ->(x) { success(x + 1) },
        add_two: ->(x) { success(x + 2) }
      })

      result = instance.transaction do |e|
        x = e.add_one(1)
        y = x + 1
        e.add_two(y)
      end

      expect(result.value!).to be(5)
    end

    it "accepts anything responding to call as operation" do
      instance = described_class.new(operations: {
        add_one: ->(x) { success(x + 1) }.method(:call)
      })

      result = instance.transaction do |e|
        e.add_one(1)
      end

      expect(result.value!).to be(2)
    end

    it "wraps with provided extension" do
      extension = Class.new do
        attr_reader :value

        def initialize
          @value = nil
        end

        def call
          result = yield

          @value = result.value! if result.success?
        end
      end.new

      instance = described_class.new(
        operations: {
          add_one: ->(x) { success(x + 1) },
          add_two: ->(x) { success(x + 2) }
        },
        extension: extension
      )

      result = instance.transaction do |e|
        x = e.add_one(1)
        e.add_two(x)
      end

      aggregate_failures do
        expect(extension.value).to be(4)
        expect(result.value!).to be(4)
      end
    end
  end

  describe "#with" do
    it "returns new instance" do
      instance = described_class.new(operations: {
        add: ->(x) { success(x + 1) }
      })

      new_instance = instance.with(add: -> {})

      expect(instance).not_to be(new_instance)
    end

    it "replaces operations" do
      instance = described_class.new(operations: {
        add: ->(x) { success(x + 1) }
      })

      new_instance = instance.with(add: ->(x) { success(x + 2) })

      result = new_instance.transaction do |e|
        e.add(1)
      end
      expect(result.value!).to be(3)
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
      instance = klass.new(operations: {
        add_one: ->(x) { success(x + 1) },
        add_two: ->(x) { success(x + 2) }
      })

      expect(instance.().value!).to be(4)
    end
  end
end
