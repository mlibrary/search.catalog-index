require "optparse"
require 'logger'
require 'date'

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

start_date = DateTime.parse(date)
start_date.upto(DateTime.now) do |date|
  date_string = date.strftime("%Y%m%d")
  logger.info "Indexing #{date_string}"
  system("bundle", "exec", "ruby", "bin/m_index_date.rb", "-d", date_string, "-s", solr_url) 
end

