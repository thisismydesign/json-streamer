require 'bundler/setup'
Bundler.setup

require 'simplecov'
SimpleCov.start do
  add_filter 'spec'
end

require 'stringio'
require 'json'
require 'ndhash'
require 'json/stream'
require 'get_process_mem'

require 'json/streamer'

DEBUG = false

def highlight(msg)
  puts("\n#{'#' * 10} #{msg} #{'#' * 10}\n\n")
  if block_given?
    yield
    puts("\n#{'#' * 8} #{msg} END #{'#' * 8}\n\n")
  end
end

def current_memory_usage
  GetProcessMem.new.mb.round
end
