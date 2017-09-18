require 'spec_helper'

RSpec.describe Json::Streamer::Conditions do
  let(:yield_level) { -1 }
  let(:yield_key) { nil }
  let(:key) { nil }
  let(:level) { 0 }
  let(:conditions) { Json::Streamer::Conditions.new(yield_level: yield_level, yield_key: yield_key) }
  let(:aggregator) { Json::Streamer::Aggregator.new }

  before do
    allow(aggregator).to receive(:key).and_return(key)
    allow(aggregator).to receive(:level).and_return(level)
  end

  RSpec.shared_examples "yield" do |method|
    context 'level' do
      context 'true' do
        let(:level) { 1 }
        let(:yield_level) { 1 }

        it 'returns whether provided level equals yield_level' do
          expect(conditions.send(method).call(aggregator: aggregator)).to be
        end
      end

      context 'false' do
        let(:level) { 2 }
        let(:yield_level) { 1 }

        it 'returns whether provided level equals yield_level' do
          expect(conditions.send(method).call(aggregator: aggregator)).to_not be
        end
      end
    end

    context 'key' do
      context 'true' do
        let(:key) { 'key' }
        let(:yield_key) { 'key' }

        it 'returns whether provided key equals yield_key' do
          expect(conditions.send(method).call(aggregator: aggregator)).to be
        end
      end

      context 'false' do
        let(:key) { 'else' }
        let(:yield_key) { 'key' }

        it 'returns whether provided key equals yield_key' do
          expect(conditions.send(method).call(aggregator: aggregator)).to_not be
        end
      end
    end
  end

  describe '#yield_value' do
    it_behaves_like "yield", :yield_value
  end

  describe '#yield_object' do
    it_behaves_like "yield", :yield_object
  end

  describe '#yield_array' do
    it_behaves_like "yield", :yield_array
  end
end
