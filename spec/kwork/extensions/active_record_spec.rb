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
    instance = Class.new(Kwork::Transaction) do
      def call
        transaction do
          step create_record
          step failure
        end
      end

      def create_record
        Kwork::Result.pure(Foo.create(bar: "bar"))
      end

      def failure
        Kwork::Result::Failure.new(:failure)
      end
    end.new(extension: Kwork::Extensions::ActiveRecord)

    instance.()

    expect(Foo.count).to be(0)
  end

  it "returns the callback result" do
    instance = Class.new(Kwork::Transaction) do
      def call
        transaction do
          step create_record
          step count
        end
      end

      def create_record
        Kwork::Result.pure(Foo.create(bar: "bar"))
      end

      def count
        Kwork::Result.pure(Foo.count)
      end
    end.new(extension: Kwork::Extensions::ActiveRecord)

    result = instance.()

    expect(result).to eq(Kwork::Result.pure(1))
  end
end
