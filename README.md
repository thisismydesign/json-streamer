# Json::Streamer

#### Ruby gem for getting data from JSON streams based on various criteria (key, nesting level, etc).

Status and support

- &#x2714; stable
- &#x2714; supported
- &#x2716; no ongoing development

<!--- Version informartion -->
*You are viewing the README of version [v2.1.0](https://github.com/thisismydesign/json-streamer/releases/tag/v2.1.0). You can find other releases [here](https://github.com/thisismydesign/json-streamer/releases).*
<!--- Version informartion end -->

| Branch | Status |
| ------ | ------ |
| Release | [![Build Status](https://travis-ci.org/thisismydesign/json-streamer.svg?branch=release)](https://travis-ci.org/thisismydesign/json-streamer)   [![Coverage Status](https://coveralls.io/repos/github/thisismydesign/json-streamer/badge.svg?branch=release)](https://coveralls.io/github/thisismydesign/json-streamer?branch=release)   [![Gem Version](https://badge.fury.io/rb/json-streamer.svg)](https://badge.fury.io/rb/json-streamer)   [![Total Downloads](http://ruby-gem-downloads-badge.herokuapp.com/json-streamer?type=total)](https://rubygems.org/gems/json-streamer) |
| Development | [![Build Status](https://travis-ci.org/thisismydesign/json-streamer.svg?branch=master)](https://travis-ci.org/thisismydesign/json-streamer)   [![Coverage Status](https://coveralls.io/repos/github/thisismydesign/json-streamer/badge.svg?branch=master)](https://coveralls.io/github/thisismydesign/json-streamer?branch=master) |

####  If you've tried JSON streaming with other Ruby libraries before (e.g. [JSON::Stream](https://github.com/dgraham/json-stream), [Yajl::FFI](https://github.com/dgraham/yajl-ffi))

This gem will basically spare you the need to define your own callbacks (i.e. implement an actual JSON parser using `start_object`, `end_object`, `key`, `value`, etc.).

#### If you're new to this

Streaming is useful for
- big files that do not fit in the memory (or you'd rather avoid the risk)
- files read in chunks (e.g. arriving over network)
- cases where you expect some issue with the file (e.g. losing connection to source, invalid data at some point) but would like to get as much data as possible anyway

This gem is aimed at making streaming as easy and convenient as possible.

#### Performance

Highly depends on the event generator. Out of the box the gem uses [JSON::Stream](https://github.com/dgraham/json-stream). It was chosen because it's a pure Ruby parser with no runtime dependencies. You can use any custom event generator, such as [Yajl::FFI](https://github.com/dgraham/yajl-ffi) which is dependent on the native YAJL library and is [~10 times faster](https://github.com/dgraham/yajl-ffi#performance). See the [Custom event generators](#custom-event-generators) chapter.

I did not measure the performance of my implementation on top of these libraries.

#### Dependencies

The gem's single runtime dependency is [JSON::Stream](https://github.com/dgraham/json-stream). It is only loaded if the default event generator is used.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'json-streamer'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install json-streamer

## Usage

```ruby
require 'json/streamer'
```

#### Passing IO upfront

Since [v1.2.0](https://github.com/thisismydesign/json-streamer/releases/tag/v1.2.0)

```ruby
file_stream = File.open('data.json', 'r')
chunk_size = 500 # defaults to 1000

streamer = Json::Streamer.parser(file_io: file_stream, chunk_size: chunk_size)
```

#### Get objects based on nesting level

```ruby
# Level zero yields the full JSON, first level yields data within the JSON 1-by-1, etc.
streamer.get(nesting_level:1) do |object|
    p object
end
```

Input:
```json
{
    "object1": "first_level_value",
    "object2": {}
}
```

Output:
```ruby
"first_level_value"
{}
```

#### Get data based on key

```ruby
streamer.get(key:'desired_key') do |object|
    p object
end
```

Input:
```json
{
    "obj1" : {
        "desired_key" : "value1"
    },
    "desired_key" : "value2",
    "obj2" : {
        "desired_key" : {
            "desired_key" : "value3"
        }
    }
}
```

Output:
```ruby
"value1"
"value2"
"value3"
{"desired_key" => "value3"}
```

#### Skip values

```ruby
streamer.get(nesting_level:1, yield_values:false) do |object|
    p object
end
```

Input:
```json
{
    "obj1" : {},
    "key" : "value"
}
```

Output:
```json
{}
```

#### Symbolize keys

Since [v1.3.0](https://github.com/thisismydesign/json-streamer/releases/tag/v1.3.0)

```ruby
streamer.get(nesting_level:0, symbolize_keys: true) do |object|
    p object
end
```

Input:
```json
{
    "obj1" : {"key" : "value"}
}
```

Output:
```ruby
{:obj1=>{:key=>"value"}}
```

#### Passing IO later (EventMachine-style)

```ruby
# Get a JsonStreamer object that provides access to the parser
# but does not start processing immediately
streamer = Json::Streamer.parser

streamer.get(nesting_level:1) do |object|
    p object
end
```

Then later in your EventMachine handler:

```ruby
def receive_data(data)
    streamer << data
end
```

#### Custom event generators

Since [v2.1.0](https://github.com/thisismydesign/json-streamer/releases/tag/v2.1.0)

```ruby
require "yajl/ffi"

Json::Streamer.parser(event_generator: Yajl::FFI::Parser.new)
```

Any parser can be used that provides the right events. The gem is tested with [Yajl::FFI](https://github.com/dgraham/yajl-ffi) and [JSON::Stream](https://github.com/dgraham/json-stream).

#### Custom yield conditions

Since [v2.0.0](https://github.com/thisismydesign/json-streamer/releases/tag/v2.0.0)

Custom conditions provide ultimate control over what to yield.

The Conditions API exposes 3 callbacks:
- `yield_value`
- `yield_array`
- `yield_object`

Each of them may be redefined. They are called once the corresponding data (value, array or object) is available. They should return whether the data should be yielded for the outside. They receive the data and the `aggregator` as parameters.

The `aggregator` exposes data about the current state of the partly parsed JSON such as:
- `level` - current level
- `key` - current key
- `value` - current value
- `key_for_level(level)` - key for custom level
- `value_for_level(level)` - value for custom level
- `get` - the raw data (in a custom format)

Example usage (inspired by [this issue](https://github.com/thisismydesign/json-streamer/issues/7#issuecomment-330232484)):

```ruby
conditions = Json::Streamer::Conditions.new
conditions.yield_value = ->(aggregator:, value:) { false }
conditions.yield_array = ->(aggregator:, array:) { false }
conditions.yield_object = lambda do |aggregator:, object:|
    aggregator.level.eql?(2) && aggregator.key_for_level(1).eql?('items1')
end

streamer.get_with_conditions(conditions) do |object|
    p object
end
```

Input:

```ruby
{
  "other": "stuff",
  "items1": [
    {
      "key1": "value"
    },
    {
      "key2": "value"
    }
  ],
  "items2": [
    {
      "key3": "value"
    },
    {
      "key4": "value"
    }
  ]
}
```

Output:

```ruby
{"key1"=>"value"}
{"key2"=>"value"}
```

#### Get an Enumerable when not passing a block

Since [v2.1.0](https://github.com/thisismydesign/json-streamer/releases/tag/v2.1.0)

When _not_ passed a block both `get` and `get_with_conditions` return an enumerator of the requested objects. When passed a block they return an empty enumerator. This means that **when _not_ passed a block the requested objects will accumulate in memory**.

Without block

```ruby
objects = streamer.get(nesting_level:1)
p objects
```

Input:
```json
{
    "object1": "first_level_value",
    "object2": {}
}
```

Output:
```ruby
["first_level_value", {}]
```

With block

```ruby
unyielded_objects = streamer.get(nesting_level:1) { |object| do_something(object) }
p unyielded_objects
```

Input:
```json
{
    "object1": "first_level_value",
    "object2": {}
}
```

Output:
```ruby
[]
```

#### Other usage information

Check the unit tests for more examples ([spec/streamer_spec.rb](spec/json/streamer/json_streamer_spec.rb)).

One `streamer` object handles one set of conditions. For multiple conditions create multiple streamers. For more details see [this discussion](https://github.com/thisismydesign/json-streamer/issues/9).

#### Deprecated API

Pre [v1.2.0](https://github.com/thisismydesign/json-streamer/releases/tag/v1.2.0)

This functionality is deprecated but kept for compatibility reasons.

```ruby
# Same as Json::Streamer.parser
streamer = Json::Streamer::JsonStreamer.new
```

```ruby
# Same as streamer << data
streamer.parser << data
```

## Contribution and feedback

This project is built around known use-cases. If you have one that isn't covered don't hesitate to open an issue and start a discussion.

Bug reports and pull requests are welcome on GitHub at https://github.com/thisismydesign/json-streamer. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## Conventions

This project follows [C-Hive guides](https://github.com/c-hive/guides) for code style, way of working and other development concerns.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
