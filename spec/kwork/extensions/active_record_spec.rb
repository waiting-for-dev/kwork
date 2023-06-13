# frozen_string_literal: true

require "kwork/adapters/result"
require "kwork/adapters/dry_monads/result"
require "kwork/adapters/dry_monads/maybe"
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

  [Kwork::Adapters::Result, Kwork::Adapters::DryMonads::Result, Kwork::Adapters::DryMonads::Maybe].each do |adapter|
    it "rolls transaction back on failure" do
      instance = Kwork::Transaction.new(
        operations: {
          add_one: -> { adapter.wrap_success(Foo.create(bar: "bar")) },
          add_two: -> { adapter.wrap_failure(:error) }
        },
        extension: described_class,
        adapter:
      )

      instance.transaction do |e|
        e.add_one
        e.add_two
      end

      expect(Foo.count).to be(0)
    end
  end
end
