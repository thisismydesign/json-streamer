# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'json/streamer/version'

Gem::Specification.new do |spec|
  spec.name          = "json-streamer"
  spec.version       = Json::Streamer::VERSION
  spec.authors       = ["Csaba Apagyi"]
  spec.email         = ["csapagyi@users.noreply.github.com"]

  spec.summary       = %q{Utility to support JSON streaming allowing you to get objects based on various criteria}
  spec.description   = %q{Useful for e.g. streaming objects from a JSON array.}
  spec.homepage      = "TODO: Put your gem's website or public repo URL here."
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.12.a"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "json-stream"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "ndhash"
end
