# frozen_string_literal: true

require "spec_helper"
require "kwork/result"

RSpec.describe Kwork::Result do
  describe ".pure" do
    it "returns a Success wrapping given value" do
      result = described_class.pure(1)

      aggregate_failures do
        expect(result).to be_a(described_class::Success)
        expect(result.value!).to eq(1)
      end
    end
  end

  describe Kwork::Result::Success do
    describe "#success?" do
      it "returns true" do
        expect(described_class.new(1).success?).to be(true)
      end
    end

    describe "#failure?" do
      it "returns true" do
        expect(described_class.new(1).failure?).to be(false)
      end
    end

    describe "#value!" do
      it "returns wrapped value" do
        expect(described_class.new(1).value!).to eq(1)
      end
    end

    describe "#failure!" do
      it "raises an error" do
        expect { described_class.new(1).failure! }.to raise_error(/no failure wrapped/)
      end
    end

    describe "#deconstruct" do
      it "deconstructs to given value" do
        expect(described_class.new(1).deconstruct).to eq([1])
      end
    end
  end

  describe Kwork::Result::Failure do
    describe "#success?" do
      it "returns false" do
        expect(described_class.new(1).success?).to be(false)
      end
    end

    describe "#failure?" do
      it "returns true" do
        expect(described_class.new(1).failure?).to be(true)
      end
    end

    describe "#value!" do
      it "raises an error" do
        expect { described_class.new(1).value! }.to raise_error(/no value wrapped/)
      end
    end

    describe "#failure!" do
      it "returns wrapped failure" do
        expect(described_class.new(1).failure!).to be(1)
      end
    end

    describe "#deconstruct" do
      it "deconstructs to given value" do
        expect(described_class.new(1).deconstruct).to eq([1])
      end
    end
  end
end
