# frozen_string_literal: true

RSpec.shared_examples 'Json::Streamer::JsonStreamer' do
  let(:example_key) { 'key' }
  let(:example_value) { 'value' }
  let(:example_hash) { { example_key => example_value } }
  let(:example_multi_level_hash) { { object1: example_hash, object2: example_hash, object3: example_hash } }
  let(:chunk_size) { 10 }
  let(:json) { JSON.generate(hash) }
  let(:json_file_mock) { StringIO.new(json) }
  let(:yielded_objects) { [] }
  let(:streamer) { described_class.new(json_file_mock, chunk_size, event_generator) }

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
      streamer = Json::Streamer.parser
      allow(streamer).to receive(:<<)

      streamer << {}

      expect(streamer).to have_received(:<<).with({})
    end
  end

  RSpec.shared_examples 'an iterable object' do
    let(:hash) { example_multi_level_hash }

    context 'when no block is passed' do
      subject(:send) { streamer.send(method, **params) }

      it 'returns an Enumerable' do
        expect(send).to be_a(Enumerable)
      end

      it 'returns array of items that would have been yielded' do
        expect(send).to eq(Array.new(3) { example_hash })
      end
    end

    context 'when a block is passed' do
      it 'yields' do
        expect do |block|
          streamer.send(method, **params, &block)
        end.to yield_control
      end
    end

    context 'when an empty block is passed' do
      it 'returns an empty Enumerable' do
        # rubocop:disable Lint/EmptyBlock
        unyielded_objects = streamer.send(method, **params) {}
        # rubocop:enable Lint/EmptyBlock

        expect(unyielded_objects).to eq([])
      end
    end
  end

  describe '#get' do
    describe 'API interaction' do
      let(:params) { { nesting_level: 1 } }
      let(:method) { :get }

      it_behaves_like 'an iterable object'
    end

    context 'when block is passed' do
      before do
        streamer.get(**params) do |object|
          yielded_objects << object
        end
      end

      describe 'nesting_level option' do
        context 'with JSON objects' do
          context 'when at 0th level of empty' do
            let(:hash) { {} }
            let(:params) { { nesting_level: 0 } }

            it 'yields empty JSON object' do
              expect(yielded_objects).to eq([{}])
            end
          end

          context 'when at 0th level' do
            let(:hash) { { example_key => example_hash } }
            let(:params) { { nesting_level: 0 } }

            it 'yields whole JSON' do
              expect(yielded_objects).to eq([{ example_key => example_hash }])
            end
          end

          context 'when at 1st level' do
            let(:hash) { example_multi_level_hash }
            let(:params) { { nesting_level: 1 } }

            it 'yields objects within JSON object' do
              expect(yielded_objects).to eq([example_hash, example_hash, example_hash])
            end
          end
        end

        context 'with JSON arrays' do
          context 'when at 0th level of flat' do
            let(:hash) { [example_value, example_value] }
            let(:params) { { nesting_level: 0 } }

            it 'yields whole array' do
              expect(yielded_objects).to eq([[example_value, example_value]])
            end
          end

          context 'when at 1st level of flat' do
            let(:hash) { Array.new(10) { example_hash } }
            let(:params) { { nesting_level: 1 } }

            it 'yields objects in array' do
              expect(yielded_objects).to eq(hash)
            end
          end

          context 'when at 1st level of multi-level' do
            let(:hash) { [[example_hash, example_hash, example_hash]] }
            let(:params) { { nesting_level: 1 } }

            it 'yields nested array' do
              expect(yielded_objects).to eq([[example_hash, example_hash, example_hash]])
            end
          end

          context 'when at 2nd level of multi-level' do
            let(:hash) { [[example_hash, example_hash, example_hash]] }
            let(:params) { { nesting_level: 2 } }

            it 'yields nested array elements' do
              expect(yielded_objects).to eq([example_hash, example_hash, example_hash])
            end
          end
        end
      end

      describe 'key option' do
        context 'with JSON objects' do
          context 'when flat, key pointing to value' do
            let(:hash) { example_hash }
            let(:params) { { key: example_key } }

            it 'yields value' do
              expect(yielded_objects).to eq([example_value])
            end
          end

          context 'with multi level, key pointing to values' do
            let(:hash) { example_multi_level_hash }
            let(:params) { { key: example_key } }

            it 'yields values' do
              expect(yielded_objects).to eq([example_value, example_value, example_value])
            end
          end

          context 'with multi level, key pointing to values and objects' do
            let(:hash) { example_multi_level_hash }
            let(:params) { { key: example_key } }

            it 'yields values and objects from all levels' do
              expect(yielded_objects).to eq([example_value, example_value, example_value])
            end
          end
        end

        context 'with JSON arrays' do
          context 'when key pointing to nested array' do
            let(:hash) { { items: [[[example_hash, example_hash, example_hash]]] } }
            let(:params) { { nesting_level: 1 } }

            it 'does not yield trailing empty arrays' do
              expect(yielded_objects.length).to eq(1)
            end

            it 'yields nested arrays with the correct nesting' do
              expect(yielded_objects).to eq([[[[example_hash, example_hash, example_hash]]]])
            end
          end

          context 'with keys pointing to array' do
            let(:hash) { { items: [example_hash, example_value, example_hash] } }
            let(:params) { { key: 'items' } }

            it 'yields array' do
              expect(yielded_objects).to eq([[example_hash, example_value, example_hash]])
            end
          end

          context 'with nested keys pointing to array' do
            let(:hash) { { items: { nested_items: [example_hash, example_value, example_hash] } } }
            let(:params) { { key: 'items' } }

            it 'keeps key pointing to arrays' do
              expect(yielded_objects).to eq([{ 'nested_items' => [example_hash, example_value, example_hash] }])
            end
          end
        end

        context 'when parsing by both JSON arrays and objects' do
          context 'with nested keys pointing to array and object' do
            let(:hash) do
              { items: { nested_items: [example_hash, example_value, example_hash] }, nested_items: example_hash }
            end
            let(:params) { { key: 'nested_items' } }

            it 'yields both array and object' do
              expect(yielded_objects).to eq([[example_hash, example_value, example_hash], example_hash])
            end
          end
        end
      end

      describe 'yield_values option' do
        let(:hash) { { obj: example_hash, obj2: { nested_obj: example_hash } } }

        context 'when enabled' do
          let(:params) { { nesting_level: 2 } }

          it 'yields values from given level' do
            expect(yielded_objects).to eq([example_value, example_hash])
          end
        end

        context 'when disabled' do
          let(:params) { { nesting_level: 2, yield_values: false } }

          it 'does not yield values from given level' do
            expect(yielded_objects).to eq([example_hash])
          end
        end
      end

      describe 'EventMachine style input' do
        let(:streamer) { Json::Streamer::JsonStreamer.new }
        let(:hash) { example_multi_level_hash }
        let(:params) { { nesting_level: 1 } }

        context 'with input piped to parser' do
          it 'yields objects within JSON object' do
            streamer.parser << json

            expect(yielded_objects).to eq([example_hash, example_hash, example_hash])
          end
        end

        context 'with chunked input piped to parser' do
          it 'yields objects within JSON object' do
            json_file_mock.each(chunk_size) do |chunk|
              streamer.parser << chunk
            end

            expect(yielded_objects).to eq([example_hash, example_hash, example_hash])
          end
        end
      end

      describe 'finished parsing' do
        let(:hash) { { obj: example_hash } }
        let(:params) { { nesting_level: 0 } }

        it 'removes object from local store' do
          expect(streamer.aggregator).to be_empty
        end
      end

      describe 'edge cases' do
        context 'when conditions overlap' do
          let(:hash) { { example_key => { example_key => example_hash } } }
          let(:params) { { key: example_key } }

          it 'consumes object on first occurrence' do
            expect(yielded_objects).to eq([example_value, {}, {}])
          end
        end

        context 'when nesting_level and key both point to the same object' do
          let(:hash) { { items: { nested_items: [example_value, example_value, example_value] } } }
          let(:params) { { key: 'nested_items', nesting_level: 2 } }

          it 'yields the object once' do
            expect(yielded_objects).to eq([[example_value, example_value, example_value]])
          end
        end
      end

      describe 'symbolize_keys option' do
        let(:hash) { { 'object' => example_hash } }
        let(:params) { { nesting_level: 0, symbolize_keys: true } }

        it 'symbolizes keys' do
          expect(yielded_objects).to eq([{ object: { key: 'value' } }])
        end
      end
    end
  end

  describe '#get_with_conditions' do
    let(:conditions) { Json::Streamer::Conditions.new(yield_key: 'nested_items') }

    describe 'API interaction' do
      let(:params) do
        conditions = Json::Streamer::Conditions.new
        conditions.yield_object = ->(aggregator:, object:) { aggregator.level.eql?(1) }
        conditions
      end
      let(:method) { :get_with_conditions }

      # Same as shared context but without keyword arguemnts
      describe 'it_behaves_like an iterable object' do
        let(:hash) { example_multi_level_hash }

        context 'when no block is passed' do
          subject(:send) { streamer.send(method, params) }

          it 'returns an Enumerable' do
            expect(send).to be_a(Enumerable)
          end

          it 'returns array of items that would have been yielded' do
            expect(send).to eq(Array.new(3) { example_hash })
          end
        end

        context 'when a block is passed' do
          it 'yields' do
            expect do |block|
              streamer.send(method, params, &block)
            end.to yield_control
          end
        end

        context 'when an empty block is passed' do
          it 'returns an empty Enumerable' do
            # rubocop:disable Lint/EmptyBlock
            unyielded_objects = streamer.send(method, params) {}
            # rubocop:enable Lint/EmptyBlock

            expect(unyielded_objects).to eq([])
          end
        end
      end
    end

    context 'when block is passed' do
      before do
        streamer.get_with_conditions(conditions) do |object|
          yielded_objects << object
        end
      end

      context 'when there are both JSON arrays and objects' do
        context 'when nested keys point to array and object' do
          let(:hash) do
            { items: { nested_items: [example_hash, example_value, example_hash] }, nested_items: example_hash }
          end

          it 'yields both array and object' do
            expect(yielded_objects).to eq([[example_hash, example_value, example_hash], example_hash])
          end
        end
      end

      context 'when cannot be solved via regular get' do
        let(:conditions) do
          conditions = Json::Streamer::Conditions.new
          conditions.yield_value = ->(aggregator:, value:) { false }
          conditions.yield_array = ->(aggregator:, array:) { false }
          conditions.yield_object = lambda do |aggregator:, object:|
            aggregator.level.eql?(2) && aggregator.key_for_level(1).eql?('items1')
          end
          conditions
        end

        let(:hash) do
          {
            other: 'stuff',
            items1: [
              {
                key1: 'value'
              },
              {
                key2: 'value'
              }
            ],
            items2: [
              {
                key3: 'value'
              },
              {
                key4: 'value'
              }
            ]
          }
        end

        it 'solves it ^^' do
          expect(yielded_objects).to eq([{ 'key1' => 'value' }, { 'key2' => 'value' }])
        end
      end
    end
  end

  describe '#get (generated)' do
    context 'with JSONs with various nesting level and number of objects per level' do
      # rubocop:disable RSpec/ExampleLength
      it 'yields all objects on desired level (checking number of yielded objects)' do
        # Setting these options to high can cause the test to run longer
        entries_per_level = 2
        max_levels = 10

        (1..max_levels).each do |max_level|
          hash = NDHash.generate(levels: max_level, values_per_level: 0, hashes_per_level: entries_per_level)
          json_file_mock = StringIO.new(JSON.generate(hash))
          streamer = Json::Streamer::JsonStreamer.new(json_file_mock)

          yielded_objects = []
          streamer.get(nesting_level: max_level - 1) do |object|
            yielded_objects << object
          end

          expect(yielded_objects.length).to eq(entries_per_level**(max_level - 1))
        end
      end
      # rubocop:enable RSpec/ExampleLength
    end
  end
end

RSpec.describe Json::Streamer::JsonStreamer do
  context 'when using default event generator' do
    let(:event_generator) { :default }

    it_behaves_like 'Json::Streamer::JsonStreamer'
  end

  context 'when using custom yajl/ffi event generator' do
    require 'yajl/ffi'
    let(:event_generator) { Yajl::FFI::Parser.new }

    it_behaves_like 'Json::Streamer::JsonStreamer'
  end
end
