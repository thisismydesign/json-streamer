# Json::Streamer

Utility to support JSON streaming allowing you to get data based on various criteria (key, nesting level, etc).

This gem will basically spare you the need to define you own callbacks when parsing JSON stream.
Streaming is useful for
- big files that not fit in the memory (or you'd rather avoid the risk)
- files read in chunks (e.g. arriving over network)
- cases where you expect some issue with the file (e.g. losing connection to source, invalid data at some point) but would like to get as much data as possible anyway

Performance:

The gem uses JSON::Stream's events in the background. It was chosen because it's a pure Ruby parser.
A similar implementation can be done using the ~10 times faster Yajl::FFI gem that is dependent on the native YAJL library.
I did not measure the performance of my implementation on top of these libraries.

I do not recommend this or any of the gems mentioned above if you don't need streaming.

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

# Get a JsonStreamer object that will parse file_stream by chunks of 500
# Default chunk size in 1000
streamer = Json::Streamer::JsonStreamer.new(file_stream, 500)
```

```ruby
# Get objects based on nesting level
# Level zero will give you the full JSON, first level will give you data within full JSON object, etc.
streamer.get(nesting_level:1).each do |object|
    p object
end
```

```json
{
    "object1": {},
    "object2": {}
}

=>

{}
{}
```

```ruby
# Get data based on key
streamer.get(key:'key').each do |object|
    p object
end
```

```json
{
    "obj1" : {
        "key" : "value"
    },
    "key" : "value",
    "obj2" : {
        "key" : {
            "key" : "value"
        }
    }
}

=>

"value"
"value"
"value"
{"key" : "value"}
```

```ruby
# You can also skip values if you'd only like to get objects and arrays
streamer.get(nesting_level:1, yield_values:false).each do |object|
    p object
end
```

```json
{
    "obj1" : {}
    "key" : "value"
}

=>

{}
```

Check the unit tests for more examples.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/csapagyi/json-streamer. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
