# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'json/streamer/version'

Gem::Specification.new do |spec|
  spec.name          = "json-streamer"
  spec.version       = Json::Streamer::VERSION
  spec.authors       = ["thisismydesign"]
  spec.email         = ["thisismydesign@users.noreply.github.com"]

  spec.summary       = %q{Utility to support JSON streaming allowing you to get data based on various criteria (key, nesting level, etc)}
  spec.homepage      = "https://github.com/thisismydesign/json-streamer"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Because of `require_relative`
  spec.required_ruby_version = '>= 1.9.2'

  spec.add_dependency "json-stream"
end
