# frozen_string_literal: true

require_relative 'aggregator'
require_relative 'callbacks'

module Json
  module Streamer
    class Parser
      def initialize(event_generator, options = {})
        @event_generator = event_generator
        @symbolize_keys = options[:symbolize_keys]

        @aggregator = Aggregator.new
        @event_consumer = Callbacks.new(@aggregator)
      end

      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Metrics/AbcSize
      def get(conditions)
        @event_generator.start_object { @event_consumer.start_object }
        @event_generator.start_array { @event_consumer.start_array }

        @event_generator.key do |k|
          @event_consumer.key(k, @symbolize_keys)
        end

        @event_generator.value do |v|
          @event_consumer.value(v) do |value|
            yield value if conditions.yield_value.call(aggregator: @aggregator, value: value)
          end
        end

        @event_generator.end_object do
          @event_consumer.end_object do |object|
            yield object if conditions.yield_object.call(aggregator: @aggregator, object: object)
          end
        end

        @event_generator.end_array do
          @event_consumer.end_array do |array|
            yield array if conditions.yield_array.call(aggregator: @aggregator, array: array)
          end
        end
      end
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/AbcSize

      def <<(data)
        @event_generator << data
      end

      def aggregator
        @aggregator.get
      end
    end
  end
end
