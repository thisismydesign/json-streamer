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
        @aggregator = {}
        @aggregator_keys = {}

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
          end_level(Hash.new) { |desired_object| yield desired_object }
        end

        @parser.end_array do
          end_level(Array.new) { |desired_object| yield desired_object }
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
        @current_key = @symbolize_keys ? k.to_sym : k
      end

      def value(value)
        reset_current_key if array_level?(@current_level)
        yield value if yield_value?
        add_value(value)
      end

      def add_value(value)
        if array_level?(@current_level)
          @aggregator[@current_level] << value
        else
          @aggregator[@current_level][@current_key] = value
        end
      end

      def end_level(type)
        if yield_object?
          yield @aggregator[@current_level].clone
          reset_current_level(type)
        else
          merge_up
        end

        @current_level -= 1
      end

      def yield_object?
        @current_level.eql?(@yield_level) or (not @yield_key.nil? and @yield_key == previous_key)
      end

      def yield_value?
        @yield_values and ((next_level).eql?(@yield_level) or (not @yield_key.nil? and @yield_key == @current_key))
      end

      def new_level(type)
        reset_current_key if array_level?(@current_level)
        set_aggregator_key
        @current_level += 1
        reset_current_level(type)
      end

      def reset_current_level(type)
        @aggregator[@current_level] = type
      end

      def set_aggregator_key
        @aggregator_keys[@current_level] = @current_key
      end

      def reset_current_key
        @current_key = nil
      end

      def array_level?(nesting_level)
        @aggregator[nesting_level].is_a?(Array)
      end

      def merge_up
        return if @current_level.zero?

        if array_level?(previous_level)
          @aggregator[previous_level] << @aggregator[@current_level]
        else
          @aggregator[previous_level][previous_key] = @aggregator[@current_level]
        end

        @aggregator.delete(@current_level)
      end

      def previous_level
        @current_level - 1
      end

      def next_level
        @current_level + 1
      end

      def previous_key
        @aggregator_keys[previous_level]
      end
    end
  end
end
