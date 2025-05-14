require_relative 'lib/json/streamer/version'

Gem::Specification.new do |spec|
  spec.name = "json-streamer"
  spec.version = Json::Streamer::VERSION
  spec.authors = ["thisismydesign"]
  spec.email = ["thisismydesign@users.noreply.github.com"]

  spec.summary = "Utility to support JSON streaming allowing you to get data based on various criteria (key, nesting level, etc)."
  spec.homepage = "https://github.com/thisismydesign/json-streamer"
  spec.license = "MIT"

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/thisismydesign/json-streamer'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Because of `require_relative`
  spec.required_ruby_version = '>= 1.9.2'

  spec.add_dependency "json-stream"
end
