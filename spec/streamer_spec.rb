require 'spec_helper'

RSpec.describe Json::Streamer::JsonStreamer do

  before(:each) do
  end

  describe '#get' do

    context 'Get first level of empty JSON object' do
      it 'should yield empty JSON object' do

        hash = {}
        json_file_mock = StringIO.new(JSON.generate(hash))
        streamer = Json::Streamer::JsonStreamer.new(json_file_mock, 10)

        objects = []
        streamer.get_objects_from_level(1) do |object|
          objects << object
        end

        expect(objects.length).to eq(1)
        expect(objects[0]).to eq({})
      end
    end

    context 'Get second level from JSON' do
      it 'should yield objects within JSON object' do

        key = 'key'
        value = 'value'
        json_object = {key => value}

        hash = {'object1':json_object, 'object2':json_object, 'object3':json_object}
        json_file_mock = StringIO.new(JSON.generate(hash))
        streamer = Json::Streamer::JsonStreamer.new(json_file_mock, 10)

        objects = []
        streamer.get_objects_from_level(2) do |object|
          objects.push(object)
        end

        expect(objects.length).to eq(hash.length)
        objects.each do |element|
          expect(element).to eq(json_object)
        end
      end
    end

    context 'Get second level from JSON array' do
      it 'should yield objects in array elements' do

        key = 'key'
        value = 'value'
        json_object = {key => value}

        array = Array.new(10) {json_object}
        json_file_mock = StringIO.new(JSON.generate(array))
        streamer = Json::Streamer::JsonStreamer.new(json_file_mock, 10)

        objects = []
        streamer.get_objects_from_level(2) do |object|
          objects << object
        end

        expect(objects.length).to eq(array.length)
        objects.each do |element|
          expect(element).to eq(json_object)
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
          streamer.get_objects_from_level(max_level) do |object|
            objects << object
          end

          expect(objects.length).to eq(entries_per_level**(max_level-1))
        end
      end
    end
  end
end
