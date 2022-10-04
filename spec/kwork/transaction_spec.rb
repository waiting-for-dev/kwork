# frozen_string_literal: true

require "kwork/result"
require "kwork/transaction"
require "spec_helper"

RSpec.describe Kwork::Transaction do
  describe "#transaction" do
    it "chains operations" do
      transaction = described_class.new(
        operations: {
          add_one: ->(x) { Kwork::Result.pure(x + 1) },
          add_two: ->(x) { Kwork::Result.pure(x + 2) }
        }
      )

      result = transaction.transaction do |e|
        two = e.add_one(1)
        e.add_two(two)
      end

      expect(result.value!).to be(4)
    end
  end

  describe "including method missing behavior" do
    it "doesn't need to delegate to the executor" do
      klass = Class.new(described_class) do
        def call
          transaction do
            two = add_one(1)
            add_two(two)
          end
        end
      end
      klass.with_method_missing
      transaction = klass.new(
        operations: {
          add_one: ->(x) { Kwork::Result.pure(x + 1) },
          add_two: ->(x) { Kwork::Result.pure(x + 2) }
        }
      )

      expect(transaction.().value!).to be(4)
    end
  end
end
