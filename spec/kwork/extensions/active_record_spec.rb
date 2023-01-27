# frozen_string_literal: true

require "kwork/adapter/result"
require "kwork/adapter/dry_monads/result"
require "kwork/adapter/dry_monads/maybe"
require "kwork/transaction"
require "kwork/extensions/active_record"

RSpec.describe Kwork::Extensions::ActiveRecord do
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

  [Kwork::Adapter::Result, Kwork::Adapter::DryMonads::Result, Kwork::Adapter::DryMonads::Maybe].each do |adapter|
    it "rolls transaction back on failure" do
      instance = Kwork::Transaction.new(
        operations: {
          add_one: -> { adapter.wrap(Foo.create(bar: "bar")) },
          add_two: -> { adapter.fail(:error) }
        },
        extension: described_class,
        adapter: adapter
      )

      instance.transaction do |e|
        e.add_one
        e.add_two
      end

      expect(Foo.count).to be(0)
    end
  end
end
