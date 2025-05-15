# frozen_string_literal: true

RSpec.describe Json::Streamer do
  describe '.parser' do
    it 'returns Json::Streamer::JsonStreamer instance' do
      expect(described_class.parser).to be_a(Json::Streamer::JsonStreamer)
    end

    it 'forwards parameters' do
      json_file_mock = StringIO.new(JSON.generate(hash))
      chunk_size = 10

      custom_generator = Object.new
      streamer = described_class.parser(file_io: json_file_mock, chunk_size: chunk_size,
                                        event_generator: custom_generator)

      expect(streamer.instance_variable_get(:@file_io)).to eq(json_file_mock)
      expect(streamer.instance_variable_get(:@chunk_size)).to eq(chunk_size)
      expect(streamer.instance_variable_get(:@event_generator)).to eq(custom_generator)
    end

    it 'defaults to `JSON::Stream::Parser` event generator' do
      expect(described_class.parser.instance_variable_get(:@event_generator)).to be_a(JSON::Stream::Parser)
    end
  end
end
