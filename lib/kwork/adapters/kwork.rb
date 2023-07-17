# frozen_string_literal: true

require "kwork/result"

module Kwork
  module Adapters
    # Adapter for {Kwork::Result}
    module Kwork
      def self.from_kwork_result(result)
        result
      end

      def self.to_kwork_result(result)
        result
      end
    end
  end
end
