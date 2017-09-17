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
        @parser.key {|k| key(k)}
      end

      def <<(data)
        @parser << data
      end

      # Callbacks containing `yield` have to be defined in the method called via block otherwise yield won't work
      def get(nesting_level: -1, key: nil, yield_values: true, symbolize_keys: false)
        @yield_level = nesting_level
        @yield_key = key
        @yield_values = yield_values
        @symbolize_keys = symbolize_keys

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

      def key(k)
        @aggregator[@current_level][:key] = @symbolize_keys ? k.to_sym : k
      end

      def current_key
        @aggregator[@current_level][:key]
      end

      def value(value)
        yield value if yield_value?
        add_value(value)
      end

      def end_level
        if yield_object?
          yield @aggregator.last[:data].clone
        else
          add_value(@aggregator.last[:data], previous_level) unless @current_level.zero?
        end

        @aggregator.pop
        @current_level -= 1
      end

      def add_value(value, level = @current_level)
        if array_level?(level)
          @aggregator[level][:data] << value
        else
          @aggregator[level][:data][@aggregator[level][:key]] = value
        end
      end

      def yield_object?
        @current_level.eql?(@yield_level) or (not @yield_key.nil? and @yield_key == previous_key)
      end

      def yield_value?
        @yield_values and ((next_level).eql?(@yield_level) or (not @yield_key.nil? and @yield_key == current_key))
      end

      def new_level(type)
        @current_level += 1
        @aggregator.push(data: type)
      end

      def array_level?(nesting_level)
        @aggregator[nesting_level][:data].is_a?(Array)
      end

      def previous_level
        @current_level - 1
      end

      def next_level
        @current_level + 1
      end

      def previous_key
        @aggregator[previous_level][:key] unless @current_level.zero?
      end
    end
  end
end
