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
    instance = Kwork::Transaction.new(
      operations: {
        create_record: -> { Kwork::Result.pure(rom.relations[:foo].command(:create).(bar: "bar")) },
        fail: -> { Kwork::Result::Failure.new(:failure) }
      },
      extension: Kwork::Extensions::ROM.curry[rom, :default]
    )

    instance.transaction do |e|
      e.create_record
      e.fail
    end

    expect(rom.relations[:foo].count).to be(0)
  end

  it "returns the callback result" do
    instance = Kwork::Transaction.new(
      operations: {
        create_record: -> { Kwork::Result.pure(rom.relations[:foo].command(:create).(bar: "bar")) },
        count: -> { Kwork::Result.pure(rom.relations[:foo].count) }
      },
      extension: Kwork::Extensions::ROM.curry[rom, :default]
    )

    result = instance.transaction do |e|
      e.create_record
      e.count
    end

    expect(result).to eq(Kwork::Result.pure(1))
  end
end
