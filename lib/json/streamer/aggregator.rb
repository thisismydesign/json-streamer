# frozen_string_literal: true

require 'forwardable'

module Json
  module Streamer
    class Aggregator
      extend Forwardable
      def_delegators :@aggregator, :pop, :push, :empty?

      def initialize
        @aggregator = []
      end

      def get
        @aggregator
      end

      def level
        @aggregator.size
      end

      def key
        @aggregator.last[:key] unless @aggregator.last.nil?
      end

      def key=(param)
        @aggregator.last[:key] = param
      end

      def value
        @aggregator.last[:value]
      end

      def value=(param)
        if array_level?
          value << param
        else
          value[key] = param
        end
      end

      def key_for_level(level)
        @aggregator[level - 1][:key] unless @aggregator[level - 1].nil?
      end

      def value_for_level(level)
        @aggregator[level - 1][:key] unless @aggregator[level - 1].nil?
      end

      private

      def array_level?
        value.is_a?(Array)
      end
    end
  end
end
