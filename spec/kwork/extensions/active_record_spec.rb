# frozen_string_literal: true

require "kwork/result"
require "kwork/transaction"
require "kwork/extensions/active_record"

RSpec.describe "Kwork::Extensions::ActiveRecord" do
  before(:all) do
    ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: "db/test.rb")

    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Schema.define do
        create_table :foos, force: true do |t|
          t.string :bar, null: false
        end
      end
    end
  end

  after(:all) { File.delete("db/test.rb") }

  before { stub_const("Foo", Class.new(ActiveRecord::Base)) }

  after { Foo.delete_all }

  it "rolls transaction back on failure" do
    instance = Kwork::Transaction.new(
      operations: {
        create_record: -> { Kwork::Result.pure(Foo.create(bar: "bar")) },
        fail: -> { Kwork::Result::Failure.new(:failure) }
      },
      extension: Kwork::Extensions::ActiveRecord
    )

    instance.transaction do |e|
      e.create_record
      e.fail
    end

    expect(Foo.count).to be(0)
  end

  it "returns the callback result" do
    instance = Kwork::Transaction.new(
      operations: {
        create_record: -> { Kwork::Result.pure(Foo.create(bar: "bar")) },
        count: -> { Kwork::Result.pure(Foo.count) }
      },
      extension: Kwork::Extensions::ActiveRecord
    )

    result = instance.transaction do |e|
      e.create_record
      e.count
    end

    expect(result).to eq(Kwork::Result.pure(1))
  end
end
