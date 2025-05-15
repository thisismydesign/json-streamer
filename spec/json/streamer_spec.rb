# frozen_string_literal: true

RSpec.describe Json::Streamer do
  describe '.parser' do
    it 'returns Json::Streamer::JsonStreamer instance' do
      expect(described_class.parser).to be_a(Json::Streamer::JsonStreamer)
    end

    it 'defaults to `JSON::Stream::Parser` event generator' do
      expect(described_class.parser.instance_variable_get(:@event_generator)).to be_a(JSON::Stream::Parser)
    end
  end
end
