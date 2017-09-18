module Json
  module Streamer
    class Conditions
      attr_accessor :yield_value, :yield_object, :yield_array

      def initialize(yield_level: -1, yield_key: nil)
        @yield_level = yield_level
        @yield_key = yield_key

        @yield_value = ->(aggregator:, value:nil) { yield?(aggregator) }
        @yield_object = ->(aggregator:, object:nil) { yield?(aggregator) }
        @yield_array = ->(aggregator:, array:nil) { yield?(aggregator) }
      end

      private

      def yield?(aggregator)
        aggregator.level.eql?(@yield_level) or (not @yield_key.nil? and @yield_key == aggregator.key)
      end
    end
  end
end
