# frozen_string_literal: true

require "spec_helper"
require "kwork/resolver"

RSpec.describe Kwork::Resolver do
  describe ".call" do
    context "when operations is an Array" do
      it "resolves operations from instance methods" do
        instance = Class.new do
          def foo = nil
          def bar = nil
        end.new
        operations = described_class.(operations: %i[foo bar], instance:)

        expect(operations).to eq({ foo: instance.method(:foo), bar: instance.method(:bar) })
      end
    end

    context "when operations is a Hash" do
      it "resolve operations from instance methods when the value is a Symbol" do
        instance = Class.new { def foo = nil }.new
        operations = described_class.(operations: { foo: :foo }, instance:)

        expect(operations).to eq({ foo: instance.method(:foo) })
      end

      it "uses the value as-is when it is a callable" do
        callable = -> {}
        operations = described_class.(operations: { foo: callable }, instance: nil)

        expect(operations).to eq({ foo: callable })
      end

      it "raises an error when the value is not a Symbol or a callable" do
        expect do
          described_class.(operations: { foo: nil }, instance: nil)
        end.to raise_error(ArgumentError, /operation must be given as/)
      end
    end

    context "when operations is not an Array or a Hash" do
      it "raises an error" do
        expect do
          described_class.(operations: nil, instance: nil)
        end.to raise_error(ArgumentError, /operations can be given as/)
      end
    end
  end
end
