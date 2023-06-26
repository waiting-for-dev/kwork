# frozen_string_literal: true

require "kwork/adapters/kwork"

RSpec.describe Kwork::Adapters::Kwork do
  describe ".from_kwork_result" do
    it "returns given result" do
      result = Kwork::Result.pure(1)

      expect(
        described_class.from_kwork_result(result)
      ).to be(result)
    end
  end

  describe ".to_kwork_result" do
    it "returns given result" do
      result = Kwork::Result.pure(1)

      expect(
        described_class.to_kwork_result(result)
      ).to be(result)
    end
  end
end
