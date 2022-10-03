# frozen_string_literal: true

require "kwork/result"

module Kwork
  # Adapter for Kwork::Result
  module ResultAdapter
    def self.wrap(value)
      Kwork::Result.pure(value)
    end

    def self.unwrap(result)
      result.value!
    end

    def self.success?(result)
      result.success?
    end
  end
end
