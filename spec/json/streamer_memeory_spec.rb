require 'spec_helper'

RSpec.describe Json::Streamer do
  describe 'memory usage' do
    let(:example_hash) { {'key' => 'value'} }

    context 'Big JSON array parsed with JSON::Stream', speed: 'slow', type: 'memory' do
      it 'should increase memory consumption' do
        highlight('MEMORY USAGE TEST (NOT streaming)')

        json_array_size = 2**16
        hash = Array.new(json_array_size) {example_hash}
        json_file_mock = StringIO.new(JSON.generate(hash))

        p "Number of elements: #{json_array_size}"
        memory_usage_before_parsing = current_memory_usage
        p "Memory consumption before parsing: #{memory_usage_before_parsing} MB"

        JSON::Stream::Parser.parse(json_file_mock)

        memory_usage_after_parsing = current_memory_usage
        p "Memory consumption after parsing: #{memory_usage_after_parsing.round} MB"

        expect(memory_usage_after_parsing).to be > 1.5 * memory_usage_before_parsing
        p "With JSON::Stream memory consumption increased with at least 150% during processing."
      end
    end

    context 'Big JSON array parsed with JSON::Streamer', speed: 'slow', type: 'memory' do
      it 'should NOT increase memory consumption'  do
        highlight('MEMORY USAGE TEST (streaming)')

        json_array_size = 2**18
        hash = Array.new(json_array_size) {example_hash}
        json_file_mock = StringIO.new(JSON.generate(hash))

        p "Number of elements: #{json_array_size}"
        memory_usage_before_parsing = current_memory_usage
        p "Memory consumption before parsing: #{memory_usage_before_parsing} MB"

        streamer = Json::Streamer.parser(file_io: json_file_mock)
        object_count = 0
        streamer.get(nesting_level:1) do |object|
          expect(object).to eq(example_hash)
          object_count += 1
        end
        expect(object_count).to eq(json_array_size)

        memory_usage_after_parsing = current_memory_usage
        p "Memory consumption after parsing: #{memory_usage_after_parsing.round} MB"

        expect(memory_usage_after_parsing).to be < 1.1 * memory_usage_before_parsing
        p "With JSON::Streamer memory consumption did not increase significantly during processing."
      end
    end
  end
end
