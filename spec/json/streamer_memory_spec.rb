require 'spec_helper'

RSpec.describe Json::Streamer do
  describe 'memory usage', speed: 'slow', type: 'memory' do
    before do
      GC.start
      highlight('MEMORY USAGE TEST')
    end

    let(:example_hash) { {'key' => rand} }
    let(:size) { 2**18 }
    let(:hash) { Array.new(size) { content } }
    let!(:json_file_mock) { StringIO.new(JSON.generate(hash)) }

    RSpec.shared_examples 'does not consumne memory' do
      it 'should NOT increase memory consumption' do
        p "Number of elements: #{size}"
        memory_usage_before_parsing = current_memory_usage
        p "Memory consumption before parsing: #{memory_usage_before_parsing} MB"

        streamer = Json::Streamer.parser(file_io: json_file_mock)
        object_count = 0
        streamer.get(nesting_level: 1) do
          object_count += 1
        end
        expect(object_count).to eq(size)

        memory_usage_after_parsing = current_memory_usage
        p "Memory consumption after parsing: #{memory_usage_after_parsing.round} MB"

        expect(memory_usage_after_parsing).to be < 1.1 * memory_usage_before_parsing
        p "With JSON::Streamer memory consumption did not increase by more than 10% during processing."
      end
    end

    context 'with streaming' do
      context 'array of objects parsed with JSON::Streamer' do
        let(:content) { example_hash }

        it_behaves_like 'does not consumne memory'
      end

      context 'array of values parsed with JSON::Streamer' do
        let(:content) { rand }

        it_behaves_like 'does not consumne memory'
      end

      context 'array of arrays parsed with JSON::Streamer' do
        let(:content) { [rand] }

        it_behaves_like 'does not consumne memory'
      end
    end

    context 'without streaming' do
      context 'array of objects parsed with JSON::Stream' do
        let(:content) { example_hash }

        it 'should increase memory consumption' do
          p "Number of elements: #{size}"
          memory_usage_before_parsing = current_memory_usage
          p "Memory consumption before parsing: #{memory_usage_before_parsing} MB"

          object = JSON::Stream::Parser.parse(json_file_mock)
          expect(object.length).to eq(size)

          memory_usage_after_parsing = current_memory_usage
          p "Memory consumption after parsing: #{memory_usage_after_parsing.round} MB"

          expect(memory_usage_after_parsing).to be > 1.5 * memory_usage_before_parsing
          p "With JSON::Stream memory consumption increased by at least 50% during processing."
        end
      end
    end
  end
end
