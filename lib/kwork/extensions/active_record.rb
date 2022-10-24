# frozen_string_literal: true

require "active_record"

module Kwork
  module Extensions
    ActiveRecord = lambda do |&transaction|
      ::ActiveRecord::Base.transaction do
        raise ::ActiveRecord::Rollback unless transaction.().success?
      end
    end
  end
end
