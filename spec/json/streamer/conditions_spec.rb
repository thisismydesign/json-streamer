# frozen_string_literal: true

RSpec.describe Json::Streamer::Conditions do
  let(:yield_level) { -1 }
  let(:yield_key) { nil }
  let(:key) { nil }
  let(:level) { 0 }
  let(:conditions) { described_class.new(yield_level: yield_level, yield_key: yield_key) }
  let(:aggregator) { Json::Streamer::Aggregator.new }

  before do
    allow(aggregator).to receive_messages(key: key, level: level)
  end

  RSpec.shared_examples 'yield' do |method|
    context 'with level' do
      context 'when true' do
        let(:level) { 1 }
        let(:yield_level) { 1 }

        it 'returns whether provided level equals yield_level' do
          expect(conditions.send(method).call(aggregator: aggregator)).to be_truthy
        end
      end

      context 'when false' do
        let(:level) { 2 }
        let(:yield_level) { 1 }

        it 'returns whether provided level equals yield_level' do
          expect(conditions.send(method).call(aggregator: aggregator)).to be_falsey
        end
      end
    end

    context 'with key' do
      context 'when true' do
        let(:key) { 'key' }
        let(:yield_key) { 'key' }

        it 'returns whether provided key equals yield_key' do
          expect(conditions.send(method).call(aggregator: aggregator)).to be_truthy
        end
      end

      context 'when false' do
        let(:key) { 'else' }
        let(:yield_key) { 'key' }

        it 'returns whether provided key equals yield_key' do
          expect(conditions.send(method).call(aggregator: aggregator)).to be_falsey
        end
      end
    end
  end

  describe '#yield_value' do
    it_behaves_like 'yield', :yield_value
  end

  describe '#yield_object' do
    it_behaves_like 'yield', :yield_object
  end

  describe '#yield_array' do
    it_behaves_like 'yield', :yield_array
  end
end
