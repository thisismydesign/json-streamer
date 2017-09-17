module Json
  module Streamer
    class Callbacks

      attr_reader :aggregator

      def initialize(conditions)
        @conditions = conditions
        @current_level = -1
        @aggregator = []
      end

      def start_object
        new_level(Hash.new)
      end

      def start_array
        new_level(Array.new)
      end

      def key(k, symbolize_keys)
        @aggregator[@current_level][:key] = symbolize_keys ? k.to_sym : k
      end

      def value(value)
        if @conditions.yield_value?(next_level, current_key)
          yield value
        else
          add_value(value)
        end
      end

      def end_level
        data = @aggregator.last[:data].clone

        @aggregator.pop
        @current_level -= 1

        if @conditions.yield?(next_level, current_key)
          yield data
        else
          add_value(data) unless @current_level < 0
        end
      end

      private

      def add_value(value)
        if array_level?(@current_level)
          @aggregator[@current_level][:data] << value
        else
          @aggregator[@current_level][:data][current_key] = value
        end
      end

      def current_key
        @aggregator[@current_level][:key] unless @current_level < 0
      end

      def new_level(type)
        @current_level += 1
        @aggregator.push(data: type)
      end

      def array_level?(nesting_level)
        @aggregator[nesting_level][:data].is_a?(Array)
      end

      def next_level
        @current_level + 1
      end
    end
  end
end
