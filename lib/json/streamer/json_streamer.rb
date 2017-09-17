require "json/stream"

module Json
  module Streamer
    class JsonStreamer

      attr_reader :parser

      def initialize(file_io = nil, chunk_size = 1000)
        @parser = JSON::Stream::Parser.new

        @file_io = file_io
        @chunk_size = chunk_size
      end

      def <<(data)
        @parser << data
      end

      def get(nesting_level: -1, key: nil, yield_values: true, symbolize_keys: false)
        conditions = Conditions.new(nesting_level, key, yield_values)
        @callbacks = Callbacks.new(conditions)

        @parser.start_object { @callbacks.start_object }
        @parser.start_array { @callbacks.start_array }

        @parser.key do |k|
          @callbacks.key(k, symbolize_keys)
        end

        @parser.value do |v|
          @callbacks.value(v) { |desired_object| yield desired_object }
        end

        @parser.end_object do
          @callbacks.end_object { |desired_object| yield desired_object }
        end

        @parser.end_array do
          @callbacks.end_array { |desired_object| yield desired_object }
        end

        @file_io.each(@chunk_size) { |chunk| @parser << chunk } if @file_io
      end

      def aggregator
        @callbacks.aggregator
      end
    end
  end
end
