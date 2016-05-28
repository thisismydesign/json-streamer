require "json/streamer/version"
require "json/stream"

module Json
  module Streamer
    class JsonStreamer
      def initialize(file_io, chunk_size = 1000)
        @parser = JSON::Stream::Parser.new

        @file_io = file_io
        @chunk_size = chunk_size

        @object_nesting_level = 0
        @current_key = nil
        @aggregator = {}
        @temp_aggregator_keys = {}

        @parser.start_object {start_object}
        @parser.start_array {start_array}
        @parser.key {|k| key(k)}
        @parser.value {|v| value(v)}

      end

      def get_objects_from_level(yield_nesting_level)
        @yield_nesting_level = yield_nesting_level

        # Callback containing yield has be defined in the method called via block
        @parser.end_object do
          if @object_nesting_level.eql? @yield_nesting_level
            yield @aggregator[@object_nesting_level].clone
            # TODO probably can be faster than reject!{true}
            @aggregator[@object_nesting_level].reject!{true}
          else
            merge_up
          end

          @object_nesting_level -= 1
        end

        @parser.end_array do
          if @object_nesting_level.eql? @yield_nesting_level
            yield @aggregator[@object_nesting_level].clone
            # TODO probably can be faster than reject!{true}
            @aggregator[@object_nesting_level].reject!{true}
          else
            merge_up
          end

          @object_nesting_level -= 1
        end

        @file_io.each(@chunk_size) do |chunk|
          @parser << chunk
        end
      end

      def start_object
        @temp_aggregator_keys[@object_nesting_level] = @current_key
        @object_nesting_level += 1
        @aggregator[@object_nesting_level] = {}
      end

      def start_array
        @temp_aggregator_keys[@object_nesting_level] = @current_key
        @object_nesting_level += 1
        @aggregator[@object_nesting_level] = []
      end

      def key k
        @current_key = k
      end

      def value v
        if @aggregator[@object_nesting_level].kind_of? Array
          @aggregator[@object_nesting_level] << v
        else
          @aggregator[@object_nesting_level][@current_key] = v
        end
      end

      def merge_up
        return if @object_nesting_level == 1
        previous_object_nesting_level = @object_nesting_level - 1
        if @aggregator[previous_object_nesting_level].kind_of? Array
          @aggregator[previous_object_nesting_level] << @aggregator[@object_nesting_level]
        else
          @aggregator[previous_object_nesting_level][@temp_aggregator_keys[previous_object_nesting_level]] = @aggregator[@object_nesting_level]
        end

        @aggregator.delete(@object_nesting_level)
        @aggregator
      end
    end
  end
end
