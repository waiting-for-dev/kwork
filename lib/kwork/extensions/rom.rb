# frozen_string_literal: true

require "rom-sql"

module Kwork
  module Extensions
    # ROM extension
    #
    # It wraps the Kwork transaction into a database transaction managed by
    # ROM, rolling back if the result is a failure.
    #
    # @see https://rom-rb.org/
    ROM = lambda do |rom, gateway, callback|
      result = nil
      rom.gateways[gateway].transaction do |t|
        result = callback.()
        raise t.rollback! unless result.success?
      end
      result
    end
  end
end
