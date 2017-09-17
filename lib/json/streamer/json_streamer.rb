require "json/stream"

module Json
  module Streamer
    class JsonStreamer

      attr_reader :aggregator
      attr_reader :parser

      def initialize(file_io = nil, chunk_size = 1000)
        @parser = JSON::Stream::Parser.new

        @file_io = file_io
        @chunk_size = chunk_size

        @current_level = -1
        @aggregator = []

        @parser.start_object {start_object}
        @parser.start_array {start_array}
      end

      def <<(data)
        @parser << data
      end

      # Callbacks containing `yield` have to be defined in the method called via block otherwise yield won't work
      def get(nesting_level: -1, key: nil, yield_values: true, symbolize_keys: false)
        @conditions = Conditions.new(nesting_level, key, yield_values)

        @parser.key do |k|
          key(k, symbolize_keys)
        end

        @parser.value do |v|
          value(v) { |desired_object| yield desired_object }
        end

        @parser.end_object do
          end_level { |desired_object| yield desired_object }
        end

        @parser.end_array do
          end_level { |desired_object| yield desired_object }
        end

        @file_io.each(@chunk_size) { |chunk| @parser << chunk } if @file_io
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
        yield value if @conditions.yield_value?(next_level, current_key)
        add_value(value)
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
