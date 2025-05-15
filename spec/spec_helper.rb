# frozen_string_literal: true

require 'simplecov'
SimpleCov.start

require 'stringio'
require 'json'
require 'ndhash'
require 'json/stream'
require 'get_process_mem'

require 'json/streamer'

DEBUG = false

def highlight(msg)
  puts("\n#{'#' * 10} #{msg} #{'#' * 10}\n\n")
  return unless block_given?

  yield
  puts("\n#{'#' * 8} #{msg} END #{'#' * 8}\n\n")
end

def current_memory_usage
  GetProcessMem.new.mb.round
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.filter_run_excluding speed: 'slow'
end
