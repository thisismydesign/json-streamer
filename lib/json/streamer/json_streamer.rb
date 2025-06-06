# frozen_string_literal: true

require_relative 'conditions'
require_relative 'parser'

module Json
  module Streamer
    class JsonStreamer
      attr_reader :parser

      def initialize(file_io = nil, chunk_size = 1000, event_generator = :default)
        @event_generator = make_event_generator(event_generator)

        @file_io = file_io
        @chunk_size = chunk_size
      end

      def <<(data)
        parser << data
      end

      # rubocop:disable Metrics/MethodLength
      def get(nesting_level: -1, key: nil, yield_values: true, symbolize_keys: false)
        conditions = Conditions.new(yield_level: nesting_level, yield_key: key)
        conditions.yield_value = ->(aggregator:, value:) { false } unless yield_values

        @parser = Parser.new(@event_generator, symbolize_keys: symbolize_keys)
        unyielded_items = []

        parser.get(conditions) do |obj|
          if block_given?
            yield obj
          else
            unyielded_items.push(obj)
          end

          obj
        end

        process_io

        unyielded_items
      end
      # rubocop:enable Metrics/MethodLength

      # rubocop:disable Metrics/MethodLength
      def get_with_conditions(conditions, options = {})
        @parser = Parser.new(@event_generator, symbolize_keys: options[:symbolize_keys])
        unyielded_items = []

        parser.get(conditions) do |obj|
          if block_given?
            yield obj
          else
            unyielded_items.push(obj)
          end
        end

        process_io

        unyielded_items
      end
      # rubocop:enable Metrics/MethodLength

      def aggregator
        parser.aggregator
      end

      private

      def process_io
        @file_io&.each(@chunk_size) { |chunk| parser << chunk }
      end

      def make_event_generator(generator)
        case generator
        when :default
          require 'json/stream'
          JSON::Stream::Parser.new
        else
          generator
        end
      end
    end
  end
end
