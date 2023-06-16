# frozen_string_literal: true

require "kwork/adapters/dry_monads/result"

RSpec.describe Kwork::Adapters::DryMonads::Result do
  describe ".success" do
    it "returns Success class" do
      expect(described_class.success).to eq(Dry::Monads::Result::Success)
    end
  end

  describe ".failure" do
    it "returns Failure class" do
      expect(described_class.failure).to eq(Dry::Monads::Result::Failure)
    end
  end

  describe ".wrap_success" do
    it "returns a Success instance wrapping given value" do
      result = described_class.wrap_success("foo")

      aggregate_failures do
        expect(result).to be_a(Dry::Monads::Result::Success)
        expect(result.value!).to eq("foo")
      end
    end
  end

  describe ".wrap_failure" do
    it "returns a Failure instance wrapping given value" do
      result = described_class.wrap_failure("foo")

      aggregate_failures do
        expect(result).to be_a(Dry::Monads::Result::Failure)
        expect(result.failure).to eq("foo")
      end
    end
  end
end
