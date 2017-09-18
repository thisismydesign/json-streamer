require_relative "streamer/json_streamer"
require_relative "streamer/conditions"
require_relative "streamer/callbacks"
require_relative "streamer/aggregator"

module Json
  module Streamer
    def self.parser(file_io: nil, chunk_size: 1000)
      JsonStreamer.new(file_io, chunk_size)
    end
  end
end
