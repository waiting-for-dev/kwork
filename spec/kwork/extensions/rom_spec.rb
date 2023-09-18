# frozen_string_literal: true

require "kwork/result"
require "kwork/transaction"
require "kwork/extensions/rom"

RSpec.describe "Kwork::Extensions::ROM" do
  let(:rom) do
    ROM.container(:sql, "sqlite:memory") do |config|
      config.default.create_table(:foo) do
        column :bar, :string
      end

      config.relation(:foo)
    end
  end

  it "rolls transaction back on failure" do
    instance = Class.new(Kwork::Transaction) do
      def initialize(rom:, **kwargs)
        @rom = rom
        super(**kwargs)
      end

      def call
        transaction do
          step create_record
          step failure
        end
      end

      def create_record
        Kwork::Result.pure(@rom.relations[:foo].command(:create).(bar: "bar"))
      end

      def failure
        Kwork::Result::Failure.new(:failure)
      end
    end.new(rom:, extension: Kwork::Extensions::ROM[rom, :default])

    instance.()

    expect(rom.relations[:foo].count).to be(0)
  end

  it "returns the callback result" do
    instance = Class.new(Kwork::Transaction) do
      def initialize(rom:, **kwargs)
        @rom = rom
        super(**kwargs)
      end

      def call
        transaction do
          step create_record
          step count
        end
      end

      def create_record
        Kwork::Result.pure(@rom.relations[:foo].command(:create).(bar: "bar"))
      end

      def count
        Kwork::Result.pure(@rom.relations[:foo].count)
      end
    end.new(rom:, extension: Kwork::Extensions::ROM[rom, :default])

    result = instance.()

    expect(result).to eq(Kwork::Result.pure(1))
  end
end
