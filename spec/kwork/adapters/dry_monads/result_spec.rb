# frozen_string_literal: true

require "kwork/adapters/dry_monads/result"

RSpec.describe Kwork::Adapters::DryMonads::Result do
  describe ".from_kwork_result" do
    context "when a success result" do
      it "converts to dry monad's success result" do
        expect(
          described_class.from_kwork_result(Kwork::Result.pure(1))
        ).to eq(Dry::Monads::Result.pure(1))
      end
    end

    context "when a failure result" do
      it "converts to dry monad's failure result" do
        expect(
          described_class.from_kwork_result(Kwork::Result::Failure.new(1))
        ).to eq(Dry::Monads::Result::Failure.new(1))
      end
    end
  end

  describe ".to_kwork_result" do
    context "when a success result" do
      it "converts to kwork success result" do
        expect(
          described_class.to_kwork_result(Dry::Monads::Result.pure(1))
        ).to eq(Kwork::Result.pure(1))
      end
    end

    context "when a failure result" do
      it "converts to kwork failure result" do
        expect(
          described_class.to_kwork_result(Dry::Monads::Result::Failure.new(1))
        ).to eq(Kwork::Result::Failure.new(1))
      end
    end
  end
end
