module Json
  module Streamer
    class Callbacks

      attr_reader :aggregator

      def initialize(conditions)
        @conditions = conditions
        @aggregator_level = -1
        @aggregator = []
      end

      def start_object
        new_level(Hash.new)
      end

      def start_array
        new_level(Array.new)
      end

      def key(k, symbolize_keys)
        @aggregator[@aggregator_level][:key] = symbolize_keys ? k.to_sym : k
      end

      def value(value)
        if @conditions.yield_value?(next_level, current_key)
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

      private

      def end_level
        data = @aggregator.last[:data].clone

        @aggregator.pop
        @aggregator_level -= 1

        if @conditions.yield?(next_level, current_key)
          yield data
        else
          add_value(data) unless @aggregator_level < 0
        end
      end

      def add_value(value)
        if array_level?(@aggregator_level)
          @aggregator[@aggregator_level][:data] << value
        else
          @aggregator[@aggregator_level][:data][current_key] = value
        end
      end

      def current_key
        @aggregator[@aggregator_level][:key] unless @aggregator_level < 0
      end

      def new_level(type)
        @aggregator_level += 1
        @aggregator.push(data: type)
      end

      def array_level?(nesting_level)
        @aggregator[nesting_level][:data].is_a?(Array)
      end

      def next_level
        @aggregator_level + 1
      end
    end
  end
end
