require 'spec_helper'

RSpec.describe Json::Streamer::JsonStreamer do
  before do
    if DEBUG
      highlight('INPUT') do
        puts JSON.pretty_generate(hash) if defined?(hash)
      end
    end
  end

  after do
    if DEBUG
      highlight('OUTPUT') do
        puts JSON.pretty_generate(yielded_objects) if defined?(yielded_objects)
      end
    end
  end

  describe '#<<' do
    it 'forwards data to parser' do
      data = {}
      streamer = Json::Streamer.parser

      expect(streamer.parser).to receive(:<<).with(data)

      streamer << data
    end
  end

  describe '#get' do
    let(:example_key) { 'key' }
    let(:example_value) { 'value' }
    let(:example_hash) { { example_key => example_value } }
    let(:example_multi_level_hash) { {object1: example_hash, object2: example_hash, object3: example_hash} }
    let(:chunk_size) { 10 }
    let(:json) { JSON.generate(hash) }
    let(:json_file_mock) { StringIO.new(json) }
    let(:yielded_objects) { [] }
    let(:streamer) { Json::Streamer::JsonStreamer.new(json_file_mock, chunk_size) }

    before do
      streamer.get(params) do |object|
        yielded_objects << object
      end
    end

    context 'by nesting_level' do
      context 'JSON objects' do
        context '0th level of empty' do
          let(:hash) { {} }
          let(:params) { { nesting_level: 0 } }

          it 'yields empty JSON object' do
            expect(yielded_objects).to eq([{}])
          end
        end

        context '0th level' do
          let(:hash) { {example_key => example_hash} }
          let(:params) { { nesting_level: 0 } }

          it 'yields whole JSON' do
            expect(yielded_objects).to eq([{ example_key => example_hash }])
          end
        end

        context '1st level' do
          let(:hash) { example_multi_level_hash }
          let(:params) { { nesting_level: 1 } }

          it 'yields objects within JSON object' do
            expect(yielded_objects).to eq([example_hash, example_hash, example_hash])
          end
        end
      end

      context 'JSON arrays' do
        context '0th level of flat' do
          let(:hash) { [example_value, example_value] }
          let(:params) { { nesting_level: 0 } }

          it 'yields whole array' do
            expect(yielded_objects).to eq([[example_value, example_value]])
          end
        end

        context '1st level of flat' do
          let(:hash) { Array.new(10) {example_hash} }
          let(:params) { { nesting_level: 1 } }

          it 'yields objects in array' do
            expect(yielded_objects).to eq(hash)
          end
        end

        context '1st level of multi-level' do
          let(:hash) { [[example_hash, example_hash, example_hash]] }
          let(:params) { { nesting_level: 1 } }

          it 'yields nested array' do
            expect(yielded_objects).to eq([[example_hash, example_hash, example_hash]])
          end
        end

        context '2nd level of multi-level' do
          let(:hash) { [[example_hash, example_hash, example_hash]] }
          let(:params) { { nesting_level: 2 } }

          it 'yields nested array elements' do
            expect(yielded_objects).to eq([example_hash, example_hash, example_hash])
          end
        end
      end
    end

    context 'by key' do
      context 'JSON objects' do
        context 'flat, key pointing to value' do
          let(:hash) { example_hash }
          let(:params) { { key: example_key } }

          it 'yields value' do
            expect(yielded_objects).to eq([example_value])
          end
        end

        context 'multi level, key pointing to values' do
          let(:hash) { example_multi_level_hash }
          let(:params) { { key: example_key } }

          it 'yields values' do
            expect(yielded_objects).to eq([example_value, example_value, example_value])
          end
        end

        context 'multi level, key pointing to values and objects' do
          let(:hash) { example_multi_level_hash }
          let(:params) { { key: example_key } }

          it 'yields values and objects from all levels' do
            expect(yielded_objects).to eq([example_value, example_value, example_value])
          end
        end
      end

      context 'JSON arrays' do
        context 'key pointing to nested array' do
          let(:hash) { { items: [[[example_hash, example_hash, example_hash]]] } }
          let(:params) { { nesting_level: 1 } }

          it 'does not yield trailing empty arrays' do
            expect(yielded_objects.length).to eq(1)
          end

          it 'yields nested arrays with the correct nesting' do
            expect(yielded_objects).to eq([[[[example_hash, example_hash, example_hash]]]])
          end
        end

        context 'keys pointing to array' do
          let(:hash) { { items: [example_hash, example_value, example_hash] } }
          let(:params) { { key: 'items' } }

          it 'yields array' do
            expect(yielded_objects).to eq([[example_hash, example_value, example_hash]])
          end
        end

        context 'nested keys pointing to array' do
          let(:hash) { { items: { nested_items: [example_hash, example_value, example_hash] } } }
          let(:params) { { key: 'items' } }

          it 'keeps key pointing to arrays' do
            expect(yielded_objects).to eq([{'nested_items' => [example_hash, example_value, example_hash]}])
          end
        end
      end

      context 'both JSON arrays and objects' do
        context 'nested keys pointing to array and object' do
          let(:hash) { { items: { nested_items: [example_hash, example_value, example_hash] }, nested_items: example_hash } }
          let(:params) { {key: 'nested_items'} }

          it 'yields both array and object' do
            expect(yielded_objects).to eq([[example_hash, example_value, example_hash], example_hash])
          end
        end
      end
    end

    context 'yield_values' do
      let(:hash) { { obj: example_hash, obj2: { nested_obj: example_hash } } }

      context 'enabled' do
        let(:params) { { nesting_level: 2 } }

        it 'yields values from given level' do
          expect(yielded_objects).to eq([example_value, example_hash])
        end
      end

      context 'disabled' do
        let(:params) { { nesting_level: 2, yield_values: false } }

        it 'does not yield values from given level' do
          expect(yielded_objects).to eq([example_hash])
        end
      end
    end

    context 'EventMachine style input' do
      let(:streamer) { Json::Streamer::JsonStreamer.new }
      let(:hash) { example_multi_level_hash }
      let(:params) { { nesting_level:1 } }

      context 'input piped to parser' do
        it 'yields objects within JSON object' do
          streamer.parser << json

          expect(yielded_objects).to eq([example_hash, example_hash, example_hash])
        end
      end

      context 'chunked input piped to parser' do
        it 'yields objects within JSON object' do
          json_file_mock.each(chunk_size) do |chunk|
            streamer.parser << chunk
          end

          expect(yielded_objects).to eq([example_hash, example_hash, example_hash])
        end
      end
    end

    context 'finished parsing' do
      let(:hash) { { obj: example_hash } }
      let(:params) { { nesting_level: 0 } }

      it 'removes object from local store' do
        expect(streamer.aggregator).to be_empty
      end
    end

    context 'edge cases' do
      context 'overlapping condition' do
        let(:hash) { { example_key => { example_key => example_hash } } }
        let(:params) { { key: example_key } }

        it 'consumes object on first occurrence' do
          expect(yielded_objects).to eq([example_value, {}, {}])
        end
      end

      context 'nesting_level and key pointing to the same object' do
        let(:hash) { { items: { nested_items: [example_value, example_value, example_value] } } }
        let(:params) { { key: 'nested_items', nesting_level: 2 } }

        it 'yields the object once' do
          expect(yielded_objects).to eq([[example_value, example_value, example_value]])
        end
      end
    end

    context 'symbolize_keys' do
      let(:hash) { hash = {'object' => example_hash} }
      let(:params) { { nesting_level: 0, symbolize_keys: true } }

      it 'symbolizes keys' do
        expect(yielded_objects).to eq([{ object: { key: 'value' } }])
      end
    end
  end

  context '#get_with_conditions' do
    let(:example_key) { 'key' }
    let(:example_value) { 'value' }
    let(:example_hash) { { example_key => example_value } }
    let(:example_multi_level_hash) { {object1: example_hash, object2: example_hash, object3: example_hash} }
    let(:chunk_size) { 10 }
    let(:json) { JSON.generate(hash) }
    let(:json_file_mock) { StringIO.new(json) }
    let(:yielded_objects) { [] }
    let(:streamer) { Json::Streamer::JsonStreamer.new(json_file_mock, chunk_size) }
    let(:params) { {yield_key: 'nested_items'} }
    let(:conditions) { Json::Streamer::Conditions.new(params) }

    before do
      streamer.get_with_conditions(conditions) do |object|
        yielded_objects << object
      end
    end

    context 'both JSON arrays and objects' do
      context 'nested keys pointing to array and object' do
        let(:hash) { { items: { nested_items: [example_hash, example_value, example_hash] }, nested_items: example_hash } }

        it 'yields both array and object' do
          expect(yielded_objects).to eq([[example_hash, example_value, example_hash], example_hash])
        end
      end
    end
  end

  context '#get (generated)' do
    context 'JSONs with various nesting level and number of objects per level' do
      it 'yields all objects on desired level (checking number of yielded objects)' do

        # Setting these options to high can cause the test to run longer
        entries_per_level = 2
        max_levels = 10

        (1..max_levels).each do |max_level|
          hash = NDHash.generate(levels: max_level, values_per_level: 0, hashes_per_level: entries_per_level)
          json_file_mock = StringIO.new(JSON.generate(hash))
          streamer = Json::Streamer::JsonStreamer.new(json_file_mock)

          yielded_objects = []
          streamer.get(nesting_level:max_level-1) do |object|
            yielded_objects << object
          end

          expect(yielded_objects.length).to eq(entries_per_level**(max_level-1))
        end
      end
    end
  end
end
