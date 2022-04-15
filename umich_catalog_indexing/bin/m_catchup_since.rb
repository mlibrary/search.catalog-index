#!/usr/local/bin/ruby

require "optparse"
require "optparse/date"
require 'logger'
require 'date'
require_relative "../lib/index_for_date"
require_relative "../lib/sftp"

logger = Logger.new($stdout)
date = DateTime.now.strftime("%Y%m%d") 
solr_url = ENV.fetch("REINDEX_SOLR_URL") 
path = ENV.fetch("DAILY_ALMA_FILES_PATH")
OptionParser.new do |opts|
  opts.on("-d", "--date", Date, "Date from which to catchup from; Default is today") do |x|
    date = x 
  end
  opts.on("-s", "--solr", "Solr url to index into. Default is #{solr_url}") do |x|
    solr_url = x
  end
   opts.on("-h", "--help", "Prints this help") do
     puts opts
     exit
   end
end.parse!

alma_files = SFTP.new.ls(path)

start_date = DateTime.parse(date)
start_date.upto(DateTime.now) do |date|
  date_string = date.strftime("%Y%m%d")
  logger.info "Indexing #{date_string}"
  IndexForDate.new(alma_files: alma_files,date: date_string, solr_url: solr_url).run
end

