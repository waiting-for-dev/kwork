# frozen_string_literal: true

require "kwork/result"
require "kwork/transaction"
require "spec_helper"

RSpec.describe Kwork::Transaction do
  def build(klass: described_class, **operations)
    klass.new(operations: operations)
  end

  def success(value)
    Kwork::Result.pure(value)
  end

  describe "#transaction" do
    it "chains operations" do
      instance = build(
        add_one: ->(x) { success(x + 1) },
        add_two: ->(x) { success(x + 2) }
      )

      result = instance.transaction do |e|
        two = e.add_one(1)
        e.add_two(two)
      end

      expect(result.value!).to be(4)
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
        add_one: ->(x) { success(x + 1) },
        add_two: ->(x) { success(x + 2) },
        klass: klass
      )

      expect(instance.().value!).to be(4)
    end
  end
end
