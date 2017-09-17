require 'spec_helper'

RSpec.describe Json::Streamer::Conditions do
  let(:yield_level) { -1 }
  let(:yield_key) { nil }
  let(:yield_values) { true }
  let(:conditions) { Json::Streamer::Conditions.new(yield_level, yield_key, yield_values) }

  RSpec.shared_examples "yield" do |method|
    context 'level' do
      let(:yield_level) { 1 }

      it 'returns whether provided level equals yield_level' do
        expect(conditions.send(method, 1, 'key')).to be
        expect(conditions.send(method, 2, 'key')).to_not be
      end
    end

    context 'key' do
      context 'yield_key procided' do
        let(:yield_key) { 'expected' }

        it 'returns whether provided key equals yield_key' do
          expect(conditions.send(method, 1, 'expected')).to be
          expect(conditions.send(method, 1, 'not expected')).to_not be
        end
      end

      it 'returns false if yield_key is nil' do
        expect(conditions.send(method, 1, nil)).to_not be
        expect(conditions.send(method, 1, 'not expected')).to_not be
      end
    end
  end

  describe '#yield?' do
    it_behaves_like "yield", :yield?
  end

  describe '#yield_values?' do
    it_behaves_like "yield", :yield_value?

    context 'yield_values is false' do
      let(:yield_values) { false }
      let(:yield_level) { 1 }
      let(:yield_key) { 'expected' }

      it 'returns false' do
        expect(conditions.yield_value?(1, 'expected')).to_not be
      end
    end
  end
end
