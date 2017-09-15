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

        @current_nesting_level = -1
        @current_key = nil
        @aggregator = {}
        @temp_aggregator_keys = {}

        @parser.start_object {start_object}
        @parser.start_array {start_array}
        @parser.key {|k| key(k)}
      end

      # Callbacks containing `yield` have to be defined in the method called via block otherwise yield won't work
      def get(nesting_level:-1, key:nil, yield_values:true)
        yield_nesting_level = nesting_level
        wanted_key = key

        @parser.value do |v|
          if in_an_array?
            if yield_values and yield_value?(yield_nesting_level)
              yield v
            else
              @aggregator[@current_nesting_level] << v
            end
          else
            @aggregator[@current_nesting_level][@current_key] = v
            if yield_values and yield_value?(yield_nesting_level, wanted_key)
              yield v
            end
          end
        end

        @parser.end_object do
          if yield_object?(yield_nesting_level, wanted_key)
            yield @aggregator[@current_nesting_level].clone
            @aggregator[@current_nesting_level] = {}
          else
            merge_up
          end

          @current_nesting_level -= 1
        end

        @parser.end_array do
          if yield_object?(yield_nesting_level, wanted_key)
            yield @aggregator[@current_nesting_level].clone
            @aggregator[@current_nesting_level] = []
          else
            merge_up
          end

          @current_nesting_level -= 1
        end

        if @file_io
          @file_io.each(@chunk_size) do |chunk|
            @parser << chunk
          end
        end
      end

      def yield_object?(yield_nesting_level, wanted_key)
        @current_nesting_level.eql? yield_nesting_level or (not wanted_key.nil? and wanted_key == @temp_aggregator_keys[@current_nesting_level-1])
      end

      def yield_value?(yield_nesting_level, wanted_key = nil)
        (@current_nesting_level + 1).eql? yield_nesting_level or (not wanted_key.nil? and wanted_key == @current_key)
      end

      def start_object
        reset_current_key if in_an_array?
        @temp_aggregator_keys[@current_nesting_level] = @current_key
        @current_nesting_level += 1
        @aggregator[@current_nesting_level] = {}
      end

      def start_array
        reset_current_key if in_an_array?
        @temp_aggregator_keys[@current_nesting_level] = @current_key
        @current_nesting_level += 1
        @aggregator[@current_nesting_level] = []
      end

      def reset_current_key
        @current_key = nil
      end

      def in_an_array?
        @aggregator[@current_nesting_level].is_a?(Array)
      end

      def key(k)
        @current_key = k
      end

      def merge_up
        return if @current_nesting_level == 0
        previous_nesting_level = @current_nesting_level - 1
        if @aggregator[previous_nesting_level].kind_of? Array
          @aggregator[previous_nesting_level] << @aggregator[@current_nesting_level]
        else
          @aggregator[previous_nesting_level][@temp_aggregator_keys[previous_nesting_level]] = @aggregator[@current_nesting_level]
        end

        @aggregator.delete(@current_nesting_level)
        @aggregator
      end
    end
  end
end
