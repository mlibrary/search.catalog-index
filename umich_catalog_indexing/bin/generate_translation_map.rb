#!/usr/local/bin/ruby
require "optparse"
require_relative "../lib/sidekiq_jobs"

force = false
tm_list = {
  "floor_location" => Jobs::TranslationMapGenerator::FloorLocations,
  "electronic_collections" => Jobs::TranslationMapGenerator::ElectronicCollections,
  "electronic_collections_ranking" => Jobs::TranslationMapGenerator::ElectronicCollectionsRanking,
}

optparse = OptionParser.new do |opts|
  opts.banner = "Usage: generate_translation_map.rb [options] floor_location|electronic_collections"

  opts.on("-f", "--force", "Force generation of given translation map even if it is less than one day old") do |x|
    force = true if x
  end
  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end
end
optparse.parse!

tm_generator = tm_list[ARGV.pop]

unless tm_generator
  puts optparse
  exit(-1)
end

Jobs::TranslationMapGenerator.generate(generator: tm_generator, force: force)
