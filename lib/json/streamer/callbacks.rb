module Json
  module Streamer
    class Callbacks
      attr_reader :aggregator

      def initialize(conditions)
        @conditions = conditions
        @aggregator = []
      end

      def start_object
        new_level(Hash.new)
      end

      def start_array
        new_level(Array.new)
      end

      def key(k, symbolize_keys)
        @aggregator.last[:key] = symbolize_keys ? k.to_sym : k
      end

      def value(value)
        if @conditions.yield_value?(current_level, current_key)
          yield value
        else
          add_value(value)
        end
      end

      def end_object
        end_level { |obj| yield obj }
      end

      def end_array
        end_level { |obj| yield obj }
      end

      def current_level
        @aggregator.size
      end

      def current_key
        key_for_level(current_level - 1)
      end

      def key_for_level(level)
        @aggregator[level][:key] unless @aggregator[level].nil?
      end

      private

      def end_level
        data = @aggregator.last[:data].clone

        @aggregator.pop

        if @conditions.yield?(current_level, current_key)
          yield data
        else
          add_value(data) unless @aggregator.empty?
        end
      end

      def add_value(value)
        if array_level?
          @aggregator.last[:data] << value
        else
          @aggregator.last[:data][current_key] = value
        end
      end

      def new_level(type)
        @aggregator.push(data: type)
      end

      def array_level?
        @aggregator.last[:data].is_a?(Array)
      end
    end
  end
end
