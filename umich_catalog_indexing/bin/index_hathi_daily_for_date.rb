#!/usr/local/bin/ruby
require "optparse"
require "optparse/date"
require "date"
require_relative "../lib/sidekiq_jobs"
require "logger"

logger = Logger.new($stdout)
date = nil
solr_url = ENV.fetch("REINDEX_SOLR_URL") 
path = ENV.fetch("DAILY_ALMA_FILES_PATH")
queue = "default"
OptionParser.new do |opts|
  opts.on("-d", "--date=DATE", Date, "DATE of hathi daily to index; required; this will index a file which has the day before's date in the filename") do |x|
    raise ArgumentError, "date must be today or earlier" if x > Date.today
    date = x
  end
  opts.on("-sSOLR", "--solr=SOLR", "Solr url to index into; options are: reindex|hatcher_prod|macc_prod; Default is reindex: #{solr_url}") do |x|
    case x
    when "reindex"
      solr_url = ENV.fetch("REINDEX_SOLR_URL") 
      queue = "reindex"
    when "hatcher_prod"
      solr_url = ENV.fetch("HATCHER_PRODUCTION_SOLR_URL") 
    when "macc_prod"
      solr_url = ENV.fetch("MACC_PRODUCTION_SOLR_URL") 
    else
      raise ArgumentError, "solr must be reindex|hatcher_prod|macc_prod"
    end
  end
  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end
end.parse!

logger.info "Starting submission of HathiTrust update for #{date};"
hathi_file = Jobs::Utilities::ZephirFile.daily_update(date)
logger.info "Sending job to index #{hathi_file} into solr: #{solr_url}" 
IndexHathi.set(queue: queue).perform_async(hathi_file, solr_url)
logger.info "Finished submission of HathiTrust update for #{date}"
