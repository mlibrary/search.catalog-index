#!/usr/local/bin/ruby
require "optparse"
require_relative "../lib/sidekiq_jobs"

force = false
OptionParser.new do |opts|
  opts.on("-f", "--force", "Force generation of floor locations translation map even if it is less than one day old") do |x|
    force = true if x
  end
  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end
end.parse!
Jobs::TranslationMapGenerator.generate(generator: Jobs::TranslationMapGenerator::FloorLocations, force: force)
