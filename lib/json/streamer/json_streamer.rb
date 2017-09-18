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
        conditions = Conditions.new(yield_level: nesting_level, yield_key: key)
        conditions.yield_value = ->(aggregator:, value:) { false } unless yield_values

        # TODO: deprecate symbolize_keys and move to initialize
        @parser = Parser.new(@event_generator, symbolize_keys: symbolize_keys)

        parser.get(conditions) do |obj|
          yield obj
        end

        process_io
      end

      def get_with_conditions(conditions, options = {})
        @parser = Parser.new(@event_generator, symbolize_keys: options[:symbolize_keys])

        parser.get(conditions) do |obj|
          yield obj
        end

        process_io
      end

      def aggregator
        parser.aggregator
      end

      private

      def process_io
        @file_io.each(@chunk_size) { |chunk| parser << chunk } if @file_io
      end
    end
  end
end
