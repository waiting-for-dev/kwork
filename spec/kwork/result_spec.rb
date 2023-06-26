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

    describe "#value_or" do
      it "returns wrapped value" do
        expect(described_class.new(1).value_or(2)).to be(1)
      end
    end

    describe "#bind" do
      it "applies given block to wrapped value and returns the result" do
        expect(described_class.new(1).bind { |x| Kwork::Result.pure(x + 1) }).to eq(described_class.new(2))
      end
    end

    describe "#map" do
      it "returns a new success which value is the result of applying given block to the former value" do
        expect(described_class.new(1).map { |x| x + 1 }).to eq(described_class.new(2))
      end
    end

    describe "#either" do
      it "applies first function to wrapped value" do
        expect(described_class.new(1).either(->(x) { x + 1 }, ->(x) { x - 1 })).to be(2)
      end
    end

    describe "#==" do
      it "returns true if other is a Success wrapping the same value" do
        # rubocop:disable RSpec/IdenticalEqualityAssertion
        expect(described_class.new(1)).to eq(described_class.new(1))
        # rubocop:enable RSpec/IdenticalEqualityAssertion
      end

      it "returns false if other is a Success wrapping a different value" do
        expect(described_class.new(1)).not_to eq(described_class.new(2))
      end

      it "returns false if other is not a Success" do
        other = Class.new do
          def initialize
            @value = 1
          end
        end.new

        expect(described_class.new(1)).not_to eq(other)
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

    describe "#value_or" do
      it "returns given value" do
        expect(described_class.new(1).value_or(2)).to be(2)
      end
    end

    describe "#bind" do
      it "returns itself" do
        expect(described_class.new(1).bind { |x| x + 1 }).to eq(described_class.new(1))
      end
    end

    describe "#map" do
      it "returns itself" do
        expect(described_class.new(1).map { |x| x + 1 }).to eq(described_class.new(1))
      end
    end

    describe "#either" do
      it "applies second function to wrapped failure" do
        expect(described_class.new(1).either(->(x) { x + 1 }, ->(x) { x - 1 })).to be(0)
      end
    end

    describe "#==" do
      it "returns true if other is a Failure wrapping the same failure" do
        # rubocop:disable RSpec/IdenticalEqualityAssertion
        expect(described_class.new(1)).to eq(described_class.new(1))
        # rubocop:enable RSpec/IdenticalEqualityAssertion
      end

      it "returns false if other is a Failure wrapping a different value" do
        expect(described_class.new(1)).not_to eq(described_class.new(2))
      end

      it "returns false if other is not a Failure" do
        other = Class.new do
          def initialize
            @failure = 1
          end
        end.new

        expect(described_class.new(1)).not_to eq(other)
      end
    end

    describe "#deconstruct" do
      it "deconstructs to given value" do
        expect(described_class.new(1).deconstruct).to eq([1])
      end
    end
  end
end
