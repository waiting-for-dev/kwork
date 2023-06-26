# frozen_string_literal: true

require "active_record"

module Kwork
  module Extensions
    ActiveRecord = lambda do |callback|
      result = nil
      ::ActiveRecord::Base.transaction do
        result = callback.()
        raise ::ActiveRecord::Rollback unless result.success?
      end
      result
    end
  end
end
