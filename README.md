# Json::Streamer

#### Ruby utility that supports JSON streaming allowing you to get data based on various criteria (key, nesting level, etc).

| Branch | Status |
| ------ | ------ |
| Release | [![Build Status](https://travis-ci.org/thisismydesign/json-streamer.svg?branch=release)](https://travis-ci.org/thisismydesign/json-streamer)   [![Coverage Status](https://coveralls.io/repos/github/thisismydesign/json-streamer/badge.svg?branch=release)](https://coveralls.io/github/thisismydesign/json-streamer?branch=release)   [![Gem Version](https://badge.fury.io/rb/json-streamer.svg)](https://badge.fury.io/rb/json-streamer)   [![Total Downloads](http://ruby-gem-downloads-badge.herokuapp.com/json-streamer?type=total)](https://rubygems.org/gems/json-streamer) |
| Development | [![Build Status](https://travis-ci.org/thisismydesign/json-streamer.svg?branch=master)](https://travis-ci.org/thisismydesign/json-streamer)   [![Coverage Status](https://coveralls.io/repos/github/thisismydesign/json-streamer/badge.svg?branch=master)](https://coveralls.io/github/thisismydesign/json-streamer?branch=master) |

*If you've tried JSON streaming with other Ruby libraries before (e.g. [JSON::Stream](https://github.com/dgraham/json-stream), [Yajl::FFI](https://github.com/dgraham/yajl-ffi)):*

This gem will basically spare you the need to define your own callbacks (i.e. implement an actual JSON parser using `start_object`, `end_object`, `key`, `value`, etc.).


*If you're new to this:*

Streaming is useful for
- big files that do not fit in the memory (or you'd rather avoid the risk)
- files read in chunks (e.g. arriving over network)
- cases where you expect some issue with the file (e.g. losing connection to source, invalid data at some point) but would like to get as much data as possible anyway

This gem is aimed at making streaming as easy and convenient as possible.

*Performance:*

The gem uses JSON::Stream's events in the background. It was chosen because it's a pure Ruby parser.
A similar implementation can be done using the ~10 times faster Yajl::FFI gem that is dependent on the native YAJL library.
I did not measure the performance of my implementation on top of these libraries.

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

### v1.2 API

Check the unit tests for more examples ([spec/streamer_spec.rb](spec/json/streamer/json_streamer_spec.rb)).

#### Passing IO upfront

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
```json
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
```json
"value1"
"value2"
"value3"
{"desired_key" : "value3"}
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
```json
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

### Legacy API (pre-v1.2)

This functionality is deprecated but kept for compatibility reasons.

```ruby
# Same as Json::Streamer.parser
streamer = Json::Streamer::JsonStreamer.new
```

```ruby
# Same as streamer << data
streamer.parser << data
```

## Feedback

Any feedback is much appreciated.

I can only tailor this project to fit use-cases I know about - which are usually my own ones. If you find that this might be the right direction to solve your problem too but you find that it's suboptimal or lacks features don't hesitate to contact me.

Please let me know if you make use of this project so that I can prioritize further efforts.

## Conventions

This gem is developed using the following conventions:
- [Bundler's guide for developing a gem](http://bundler.io/v1.14/guides/creating_gem.html)
- [Better Specs](http://www.betterspecs.org/)
- [Semantic versioning](http://semver.org/)
- [RubyGems' guide on gem naming](http://guides.rubygems.org/name-your-gem/)
- [RFC memo about key words used to Indicate Requirement Levels](https://tools.ietf.org/html/rfc2119)
- [Bundler improvements](https://github.com/thisismydesign/bundler-improvements)

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/thisismydesign/json-streamer. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
