require 'spec_helper'

RSpec.describe Json::Streamer do
  describe '.parser' do
    it 'returns Json::Streamer::JsonStreamer instance' do
      expect(Json::Streamer.parser).to be_a(Json::Streamer::JsonStreamer)
    end

    it 'forwards parameters' do
      json_file_mock = StringIO.new(JSON.generate(hash))
      chunk_size = 10

      custom_generator = Object.new
      streamer = Json::Streamer.parser(file_io: json_file_mock, chunk_size: chunk_size, event_generator: custom_generator)

      expect(streamer.instance_variable_get(:@file_io)).to eq(json_file_mock)
      expect(streamer.instance_variable_get(:@chunk_size)).to eq(chunk_size)
      expect(streamer.instance_variable_get(:@event_generator)).to eq(custom_generator)
    end
  end
end
