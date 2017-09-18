require "json/stream"

require_relative 'conditions'
require_relative 'parser'

module Json
  module Streamer
    class JsonStreamer

      attr_reader :parser

      def initialize(file_io = nil, chunk_size = 1000)
        @event_generator = JSON::Stream::Parser.new

        @file_io = file_io
        @chunk_size = chunk_size
      end

      def <<(data)
        parser << data
      end

      def get(nesting_level: -1, key: nil, yield_values: true, symbolize_keys: false)
        conditions = Conditions.new(nesting_level, key, yield_values)
        @parser = Parser.new(@event_generator, symbolize_keys: symbolize_keys)

        parser.get(conditions) do |obj|
          yield obj
        end

        @file_io.each(@chunk_size) { |chunk| parser << chunk } if @file_io
      end

      def aggregator
        parser.aggregator
      end
    end
  end
end
