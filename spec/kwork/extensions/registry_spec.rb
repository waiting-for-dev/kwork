# frozen_string_literal: true

require "kwork/extensions/registry"

RSpec.describe Kwork::Extensions::Registry do
  describe "#initialize" do
    it "adds active_record extension" do
      registry = described_class.new

      expect(registry.fetch(:active_record)).to be(Kwork::Extensions::ActiveRecord)
    end
  end

  describe "#register" do
    it "registers an extension" do
      registry = described_class.new

      registry.register(:foo, :bar)

      expect(registry.fetch(:foo)).to be(:bar)
    end
  end

  describe "#fetch" do
    it "fetches an extension" do
      registry = described_class.new

      registry.register(:foo, :bar)

      expect(registry.fetch(:foo)).to be(:bar)
    end

    it "raises an error if the extension is not registered" do
      registry = described_class.new

      expect { registry.fetch(:foo) }.to raise_error(KeyError, /:active_record/)
    end
  end
end
