# frozen_string_literal: true

require "rom-sql"

module Kwork
  module Extensions
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
