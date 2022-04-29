#!/usr/local/bin/ruby

require "optparse"
require "optparse/date"
require 'logger'
require 'date'
require_relative "../lib/sidekiq_jobs"
require_relative "../lib/index_for_date"

logger = Logger.new($stdout)
date = DateTime.now.strftime("%Y%m%d") 
solr_url = ENV.fetch("REINDEX_SOLR_URL") 
path = ENV.fetch("DAILY_ALMA_FILES_PATH")
OptionParser.new do |opts|
  opts.on("-d", "--date=DATE", Date, "Date from which to catchup from. Default is today") do |x|
    raise ArgumentError, "date must be today or earlier" if x > Date.today
    date = x.strftime("%Y%m%d")
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
  end
   opts.on("-h", "--help", "Prints this help") do
     puts opts
     exit
   end
end.parse!

alma_files = Jobs::Utilities::SFTP.new.ls(path)

start_date = DateTime.parse(date)
start_date.upto(DateTime.now) do |date|
  date_string = date.strftime("%Y%m%d")
  logger.info "Indexing #{date_string}"
  IndexForDate.new(alma_files: alma_files,date: date_string, solr_url: solr_url).run
end

