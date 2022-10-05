# frozen_string_literal: true

require "kwork/result"
require "kwork/transaction"
require "spec_helper"

RSpec.describe Kwork::Transaction do
  def build(operations, klass: described_class)
    klass.new(operations: operations)
  end

  def success(value)
    Kwork::Result.pure(value)
  end

  def failure(value)
    Kwork::Result::Failure.new(value)
  end

  describe "#transaction" do
    it "chains operations" do
      instance = build({
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
      instance = build({
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
      instance = build({
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
      instance = build({
                         add_one: ->(x) { success(x + 1) }.method(:call)
                       })

      result = instance.transaction do |e|
        e.add_one(1)
      end

      expect(result.value!).to be(2)
    end

    it "operations can be given as anything responding to `#to_h`" do
      operations = Class.new do
        def initialize(add_one, add_two)
          @add_one = add_one
          @add_two = add_two
        end

        def to_h
          {
            add_one: @add_one,
            add_two: @add_two
          }
        end
      end.new(->(x) { success(x + 1) }, ->(x) { success(x + 2) })

      instance = build(operations)

      result = instance.transaction do |e|
        x = e.add_one(1)
        e.add_two(x)
      end

      expect(result.value!).to be(4)
    end
  end

  describe "#with" do
    it "returns new instance" do
      instance = build({
                         add: ->(x) { success(x + 1) }
                       })

      new_instance = instance.with(add: -> {})

      expect(instance).not_to be(new_instance)
    end

    it "replaces operations" do
      instance = build({
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
      instance = build(
        {
          add_one: ->(x) { success(x + 1) },
          add_two: ->(x) { success(x + 2) }
        },
        klass: klass
      )

      expect(instance.().value!).to be(4)
    end
  end
end
