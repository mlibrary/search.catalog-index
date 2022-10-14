#!/usr/local/bin/ruby

require "optparse"
require "logger"
require_relative "../lib/sidekiq_jobs"

solr_url = ENV.fetch("REINDEX_SOLR_URL") 
solr = "reindex"
file = ""
OptionParser.new do |opts|
  opts.on("-f", "--file FILE", "File on sftp server to index; Required") do |x|
    file = x
  end
  opts.on("-sSOLR", "--solr=SOLR", "Solr url to index into; options are: reindex|hatcher_prod|macc_prod; Default is reindex: #{solr_url}") do |x|
    case x
    when "reindex"
      solr_url = ENV.fetch("REINDEX_SOLR_URL") 
    when "hatcher_prod"
      solr_url = ENV.fetch("HATCHER_PRODUCTION_SOLR_URL") 
    when "macc_prod"
      solr_url = ENV.fetch("MACC_PRODUCTION_SOLR_URL") 
    else
      raise ArgumentError, "solr must be reindex|hatcher_prod|macc_prod"
    end
    solr = x
  end
   opts.on("-h", "--help", "Prints this help") do
     puts opts
     exit
   end
end.parse!

if solr == "reindex"
  puts "indexing #{file} into #{solr_url} in reindex queue"
  IndexIt.set(queue: "reindex").perform_async(file, solr_url)
else
  puts "indexing #{file} into #{solr_url} in default queue"
  IndexIt.perform_async(file, solr_url)
end
