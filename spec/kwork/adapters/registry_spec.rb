# frozen_string_literal: true

require "kwork/adapters/registry"

RSpec.describe Kwork::Adapters::Registry do
  describe "#initialize" do
    it "adds kwork adapter" do
      registry = described_class.new

      expect(registry.fetch(:kwork)).to be(Kwork::Adapters::Kwork)
    end

    it "adds dry-monad's result adapter" do
      registry = described_class.new

      expect(registry.fetch(:result)).to be(Kwork::Adapters::DryMonads::Result)
    end

    it "adds dry-monad's maybe adapter" do
      registry = described_class.new

      expect(registry.fetch(:maybe)).to be(Kwork::Adapters::DryMonads::Maybe)
    end
  end

  describe "#register" do
    it "registers an adapter" do
      registry = described_class.new

      registry.register(:foo, :bar)

      expect(registry.fetch(:foo)).to be(:bar)
    end
  end

  describe "#fetch" do
    it "fetches an adapter" do
      registry = described_class.new

      registry.register(:foo, :bar)

      expect(registry.fetch(:foo)).to be(:bar)
    end

    it "raises an error if the adapter is not registered" do
      registry = described_class.new

      expect { registry.fetch(:foo) }.to raise_error(KeyError, /:result/)
    end
  end
end
