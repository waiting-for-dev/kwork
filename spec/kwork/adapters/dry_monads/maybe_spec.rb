# frozen_string_literal: true

require "kwork/adapters/dry_monads/maybe"

RSpec.describe Kwork::Adapters::DryMonads::Maybe do
  describe ".from_kwork_result" do
    context "when a success result" do
      it "converts to dry monad's some maybe" do
        expect(
          described_class.from_kwork_result(Kwork::Result.pure(1))
        ).to eq(Dry::Monads::Some.pure(1))
      end
    end

    context "when a failure result" do
      it "converts to dry monad's none maybe" do
        expect(
          described_class.from_kwork_result(Kwork::Result::Failure.new(1))
        ).to eq(Dry::Monads::Maybe::None.new)
      end
    end
  end

  describe ".to_kwork_result" do
    context "when a some result" do
      it "converts to kwork success result" do
        expect(
          described_class.to_kwork_result(Dry::Monads::Maybe.pure(1))
        ).to eq(Kwork::Result.pure(1))
      end
    end

    context "when a none result" do
      it "converts to kwork failure result with `nil` as failure" do
        expect(
          described_class.to_kwork_result(Dry::Monads::Maybe::None.new)
        ).to eq(Kwork::Result::Failure.new(nil))
      end
    end
  end
end
