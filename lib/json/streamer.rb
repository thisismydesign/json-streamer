# frozen_string_literal: true

require_relative 'streamer/json_streamer'

module Json
  module Streamer
    def self.parser(file_io: nil, chunk_size: 1000, event_generator: :default)
      JsonStreamer.new(file_io, chunk_size, event_generator)
    end
  end
end
