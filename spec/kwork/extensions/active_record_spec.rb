# frozen_string_literal: true

require "kwork/result"
require "kwork/transaction"
require "kwork/extensions/active_record"

RSpec.describe Kwork::Extensions::ActiveRecord do
  def success(value)
    Kwork::Result.pure(value)
  end

  def failure(value)
    Kwork::Result::Failure.new(value)
  end

  before(:all) do
    ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: "db/test.rb")

    ActiveRecord::Schema.define do
      create_table :foos, force: true do |t|
        t.string :bar, null: false
      end
    end
  end

  after(:all) { File.delete("db/test.rb") }

  before { stub_const("Foo", Class.new(ActiveRecord::Base)) }

  after { Foo.delete_all }

  it "rolls transaction back on failure" do
    instance = Kwork::Transaction.new(
      operations: {
        add_one: -> { success(Foo.create(bar: "bar")) },
        add_two: -> { failure(:error) }
      },
      extension: described_class
    )

    instance.transaction do |e|
      e.add_one
      e.add_two
    end

    expect(Foo.count).to be(0)
  end
end
