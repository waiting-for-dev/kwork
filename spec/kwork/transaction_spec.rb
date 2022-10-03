# frozen_string_literal: true

require "kwork/result"
require "kwork/transaction"
require "spec_helper"

RSpec.describe Kwork::Transaction do
  describe "#transaction" do
    it "chains operations" do
      kwork = described_class.new(
        operations: {
          add_one: ->(x) { Kwork::Result.pure(x + 1) },
          add_two: ->(x) { Kwork::Result.pure(x + 2) }
        }
      )

      result = kwork.transaction do |e|
        two = e.add_one(1)
        e.add_two(two)
      end

      expect(result.value!).to be(4)
    end
  end
end
