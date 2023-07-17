# frozen_string_literal: true

require "active_record"

module Kwork
  module Extensions
    # ActiveRecord extension
    #
    # It wraps the Kwork transaction into a database transaction managed by
    # ActiveRecord, rolling back if the result is a failure.
    #
    # @see https://guides.rubyonrails.org/active_record_basics.html
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
