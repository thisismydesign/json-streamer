module Json
  module Streamer
    class Conditions

      def initialize(yield_level, yield_key, yield_values)
        @yield_level = yield_level
        @yield_key = yield_key
        @yield_values = yield_values
      end

      def yield_value?(aggregator)
        @yield_values and yield?(aggregator.level, aggregator.key)
      end

      def yield_object?(aggregator)
        yield?(aggregator.level, aggregator.key)
      end

      def yield_array?(aggregator)
        yield?(aggregator.level, aggregator.key)
      end

      private

      def yield?(level, key)
        level.eql?(@yield_level) or (not @yield_key.nil? and @yield_key == key)
      end
    end
  end
end
