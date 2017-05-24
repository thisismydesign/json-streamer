require 'spec_helper'
require 'json/stream'
require 'get_process_mem'


RSpec.describe Json::Streamer::JsonStreamer do

  before(:each) do
    @example_key = 'key'
    @example_value = 'value'
    @example_hash = {@example_key => @example_value}
  end

  describe '#get' do

    context '0th level of empty JSON object' do
      it 'should yield empty JSON object' do

        hash = {}
        json_file_mock = StringIO.new(JSON.generate(hash))
        streamer = Json::Streamer::JsonStreamer.new(json_file_mock, 10)

        objects = []
        streamer.get(nesting_level:0) do |object|
          objects << object
        end

        expect(objects.length).to eq(1)
        expect(objects[0]).to eq({})
      end
    end

    context '1st level from JSON' do
      it 'should yield objects within JSON object' do

        hash = {'object1':@example_hash, 'object2':@example_hash, 'object3':@example_hash}
        json_file_mock = StringIO.new(JSON.generate(hash))
        streamer = Json::Streamer::JsonStreamer.new(json_file_mock, 10)

        objects = []
        streamer.get(nesting_level:1) do |object|
          objects.push(object)
        end

        expect(objects.length).to eq(hash.length)
        objects.each do |element|
          expect(element).to eq(@example_hash)
        end
      end
    end

    context '1st level from JSON array' do
      it 'should yield objects in array elements' do

        array = Array.new(10) {@example_hash}
        json_file_mock = StringIO.new(JSON.generate(array))
        streamer = Json::Streamer::JsonStreamer.new(json_file_mock, 10)

        objects = []
        streamer.get(nesting_level:1) do |object|
          objects << object
        end

        expect(objects.length).to eq(array.length)
        objects.each do |element|
          expect(element).to eq(@example_hash)
        end
      end
    end

    context 'JSONs with various nesting level and number of objects per level' do
      it 'should yield all objects on desired level (checking number of yielded objects)' do

        # Setting these options to high can cause the test to run longer
        entries_per_level = 2
        max_levels = 10

        (1..max_levels).each do |max_level|
          hash = NDHash.generate(levels: max_level, values_per_level: 0, hashes_per_level: entries_per_level)
          json_file_mock = StringIO.new(JSON.generate(hash))
          streamer = Json::Streamer::JsonStreamer.new(json_file_mock, 10)

          objects = []
          streamer.get(nesting_level:max_level-1) do |object|
            objects << object
          end

          expect(objects.length).to eq(entries_per_level**(max_level-1))
        end
      end
    end

    context 'Finished parsing' do
      it 'should remove object from memory' do

        hash = {obj:@example_hash}
        json_file_mock = StringIO.new(JSON.generate(hash))
        streamer = Json::Streamer::JsonStreamer.new(json_file_mock, 10)

        streamer.get(nesting_level:0) {}

        expect(streamer.aggregator[0].size).to eq(0)
      end
    end

    context 'Yield values enabled' do
      it 'should yield values from given level' do

        hash = {obj:@example_hash}
        json_file_mock = StringIO.new(JSON.generate(hash))
        streamer = Json::Streamer::JsonStreamer.new(json_file_mock, 10)

        objects = []
        streamer.get(nesting_level:2) do |object|
          objects << object
        end

        expect(objects.length).to eq(1)
        expect(objects[0]).to eq(@example_value)
      end
    end

    context 'Yield values disabled' do
      it 'should not yield values from given level' do

        hash = {obj:@example_hash}
        json_file_mock = StringIO.new(JSON.generate(hash))
        streamer = Json::Streamer::JsonStreamer.new(json_file_mock, 10)

        objects = []
        streamer.get(nesting_level:2, yield_values:false) do |object|
          objects << object
        end

        expect(objects.length).to eq(0)
      end
    end

    context 'By key from flat JSON' do
      it 'should yield value within JSON object' do

        json_file_mock = StringIO.new(JSON.generate(@example_hash))
        streamer = Json::Streamer::JsonStreamer.new(json_file_mock, 10)

        objects = []
        streamer.get(key:@example_key) do |object|
          objects.push(object)
        end

        expect(objects.length).to eq(@example_hash.length)
        objects.each do |element|
          expect(element).to eq(@example_value)
        end
      end
    end

    context 'By key from multi level JSON' do
      it 'should yield values within JSON object second level' do

        hash = {obj1:@example_hash, obj2:@example_hash, obj3:@example_hash}
        json_file_mock = StringIO.new(JSON.generate(hash))
        streamer = Json::Streamer::JsonStreamer.new(json_file_mock, 10)

        objects = []
        streamer.get(key:@example_key) do |object|
          objects.push(object)
        end

        expect(objects.length).to eq(hash.length)
        objects.each do |element|
          expect(element).to eq(@example_value)
        end
      end
    end

    context 'By key from multi level JSON' do
      it 'should yield values within JSON object from all levels the key occurs' do

        hash = {'obj1' => @example_hash, @example_key => @example_value}
        json_file_mock = StringIO.new(JSON.generate(hash))
        streamer = Json::Streamer::JsonStreamer.new(json_file_mock, 10)

        objects = []
        streamer.get(key:@example_key) do |object|
          objects.push(object)
        end

        expect(objects.length).to eq(2)
        objects.each do |element|
          expect(element).to eq(@example_value)
        end
      end
    end

    context 'By key from multi level JSON' do
      it 'should yield values and objects as well within JSON object from all levels the key occurs' do

        hash = {'obj1' => @example_hash, @example_key => @example_value, 'obj2' => {@example_key => @example_hash}}
        json_file_mock = StringIO.new(JSON.generate(hash))
        streamer = Json::Streamer::JsonStreamer.new(json_file_mock, 10)

        objects = []
        streamer.get(key:@example_key) do |object|
          objects.push(object)
        end

        expect(objects.length).to eq(4)
        objects[0..2].each do |element|
          expect(element).to eq(@example_value)
        end
        expect(objects[3]).to eq(@example_hash)
      end
    end

    context '2nd level of multi-level JSON array' do
      it 'should yield array elements' do

        hash = [[@example_hash, @example_hash, @example_hash]]
        json_file_mock = StringIO.new(JSON.generate(hash))
        streamer = Json::Streamer::JsonStreamer.new(json_file_mock, 10)

        objects = []
        streamer.get(nesting_level:2) do |object|
          objects.push(object)
        end

        expect(objects.length).to eq(3)
        objects.each do |element|
          expect(element).to eq(@example_hash)
        end
      end
    end

    context '1st level of multi-level JSON array' do
      it 'should yield array' do

        hash = [[@example_hash, @example_hash, @example_hash]]
        json_file_mock = StringIO.new(JSON.generate(hash))
        streamer = Json::Streamer::JsonStreamer.new(json_file_mock, 10)

        objects = []
        streamer.get(nesting_level:1) do |object|
          objects.push(object)
        end

        expect(objects.length).to eq(1)
        objects.each do |element|
          expect(element).to eq([@example_hash, @example_hash, @example_hash])
        end
      end
    end

    context '0th level of JSON array' do
      it 'should yield whole array' do

        hash = [@example_value, @example_value]
        json_file_mock = StringIO.new(JSON.generate(hash))
        streamer = Json::Streamer::JsonStreamer.new(json_file_mock, 10)

        objects = []
        streamer.get(nesting_level:0) do |object|
          objects.push(object)
        end

        expect(objects.length).to eq(1)
        expect(objects[0]).to eq([@example_value, @example_value])
      end
    end

    context '1th level of JSON array' do
      it 'should yield array elements' do

        hash = [@example_value, @example_value]
        json_file_mock = StringIO.new(JSON.generate(hash))
        streamer = Json::Streamer::JsonStreamer.new(json_file_mock, 10)

        objects = []
        streamer.get(nesting_level:1) do |object|
          objects.push(object)
        end

        expect(objects.length).to eq(2)
        objects.each do |element|
          expect(element).to eq(@example_value)
        end
      end
    end

    context 'Big JSON array parsed with JSON::Stream', :speed => 'slow', :type => 'memory' do
      it 'should increase memory consumption' do

        json_array_size = 2**16
        hash = Array.new(json_array_size) {@example_hash}
        json_file_mock = StringIO.new(JSON.generate(hash))

        memory_consumption_before_parsing = GetProcessMem.new.mb
        obj = JSON::Stream::Parser.parse(json_file_mock)
        memory_consumption_after_parsing = GetProcessMem.new.mb

        p "Number of elements: #{json_array_size}"
        p "Memory consumption before and after parsing: #{memory_consumption_before_parsing.round} MB -  #{memory_consumption_after_parsing.round} MB"
        expect(memory_consumption_after_parsing).to be > 1.5 * memory_consumption_before_parsing
        p "With JSON::Stream memory consumption increased with at least 150% during processing."
      end
    end

    context 'Big JSON array parsed with JSON::Streamer', :speed => 'slow', :type => 'memory' do
      it 'should NOT increase memory consumption'  do

        json_array_size = 2**18
        hash = Array.new(json_array_size) {@example_hash}
        json_file_mock = StringIO.new(JSON.generate(hash))

        memory_consumption_before_parsing = GetProcessMem.new.mb

        streamer = Json::Streamer::JsonStreamer.new(json_file_mock, 10)
        object_count = 0
        streamer.get(nesting_level:1) do |object|
          expect(object).to eq(@example_hash)
          object_count += 1
        end
        expect(object_count).to eq(json_array_size)

        memory_consumption_after_parsing = GetProcessMem.new.mb

        p "Number of elements: #{json_array_size}"
        p "Memory consumption before and after parsing: #{memory_consumption_before_parsing.round} MB -  #{memory_consumption_after_parsing.round} MB"
        expect(memory_consumption_after_parsing).to be < 1.1 * memory_consumption_before_parsing
        p "With JSON::Streamer memory consumption did not increase significantly during processing."
      end
    end

  end

end
