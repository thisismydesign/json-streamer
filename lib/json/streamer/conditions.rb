module Json
  module Streamer
    class Conditions

      def initialize(yield_level, yield_key, yield_values)
        @yield_level = yield_level
        @yield_key = yield_key
        @yield_values = yield_values
      end

      def yield_value?(level, key)
        @yield_values and yield?(level, key)
      end

      def yield?(level, key)
        level.eql?(@yield_level) or (not @yield_key.nil? and @yield_key == key)
      end
    end
  end
end
