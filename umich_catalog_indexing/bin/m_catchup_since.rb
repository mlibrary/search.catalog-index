require "optparse"
require 'logger'
require 'date'
require_relative "../lib/index_for_date"
require_relative "../lib/sftp"

logger = Logger.new($stdout)
date = '' 
solr_url = ENV.fetch("REINDEX_SOLR_URL") 
path = "bib_search"
OptionParser.new do |opts|
  opts.on("-d --date DATE") do |x|
    date = x 
  end
  opts.on("-s", "--solr SOLR") do |x|
    solr_url = x
  end
end.parse!

alma_files = SFTP.new.ls(path)

start_date = DateTime.parse(date)
start_date.upto(DateTime.now) do |date|
  date_string = date.strftime("%Y%m%d")
  logger.info "Indexing #{date_string}"
  IndexForDate.new(alma_files: alma_files,date: date_string, solr_url: solr_url).run
end

