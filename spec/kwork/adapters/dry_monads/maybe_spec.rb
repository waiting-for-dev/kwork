# frozen_string_literal: true

require "kwork/adapters/dry_monads/maybe"

RSpec.describe Kwork::Adapters::DryMonads::Maybe do
  describe ".success" do
    it "returns Some class" do
      expect(described_class.success).to eq(Dry::Monads::Maybe::Some)
    end
  end

  describe ".failure" do
    it "returns None class" do
      expect(described_class.failure).to eq(Dry::Monads::Maybe::None)
    end
  end

  describe ".wrap_success" do
    it "returns a Some instance wrapping given value" do
      result = described_class.wrap_success("foo")

      aggregate_failures do
        expect(result).to be_a(Dry::Monads::Maybe::Some)
        expect(result.value!).to be("foo")
      end
    end
  end

  describe ".wrap_failure" do
    it "returns a None Instance" do
      expect(described_class.wrap_failure("foo")).to be_a(Dry::Monads::Maybe::None)
    end
  end
end
