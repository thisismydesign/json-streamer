# frozen_string_literal: true

module Json
  module Streamer
    class Callbacks
      attr_reader :aggregator

      def initialize(aggregator)
        @aggregator = aggregator
      end

      def start_object
        new_level({})
      end

      def start_array
        new_level([])
      end

      def key(k, symbolize_keys)
        @aggregator.key = symbolize_keys ? k.to_sym : k
      end

      def value(value)
        used = yield value
        add_value(value) unless used
      end

      def end_object(&)
        end_level(&)
      end

      def end_array(&)
        end_level(&)
      end

      private

      def end_level
        data = @aggregator.value.clone

        @aggregator.pop

        used = yield data
        add_value(data) unless used || @aggregator.empty?
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
