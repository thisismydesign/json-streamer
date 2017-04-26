require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

desc "Check if source can be required locally"
task :require do
  require_relative 'lib/json/streamer'
end

task :default => [:spec, :require]
