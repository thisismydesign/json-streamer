module Json
  module Streamer
    class Callbacks
      attr_reader :aggregator

      def initialize(conditions)
        @conditions = conditions
        @aggregator = Aggregator.new
      end

      def start_object
        new_level(Hash.new)
      end

      def start_array
        new_level(Array.new)
      end

      def key(k, symbolize_keys)
        @aggregator.key = symbolize_keys ? k.to_sym : k
      end

      def value(value)
        if @conditions.yield_value?(@aggregator.level, @aggregator.key)
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
        data = @aggregator.value.clone

        @aggregator.pop

        if @conditions.yield?(@aggregator.level, @aggregator.key)
          yield data
        else
          add_value(data) unless @aggregator.empty?
        end
      end

      def add_value(value)
        @aggregator.value = value
      end

      def new_level(type)
        @aggregator.push(value: type)
      end
    end
  end
end
