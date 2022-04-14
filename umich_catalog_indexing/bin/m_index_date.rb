require_relative "../lib/jobs"
require_relative "../lib/sftp"
require "optparse"
require 'logger'

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

files = SFTP.new.ls(path).select{|x| x.match?(date)}
logger.info("files for #{date}: #{files}")
files.select{|x| x.match?(/_delete\.tar/)}.each do |file|
  logger.info("deleting file: #{file}")
  DeleteIt.new.perform(file, solr_url)
end
files.select{|x| x.match?(/_new\.tar/)}.each do |file|
  logger.info("indexing file: #{file}")
  IndexIt.new.perform(file, solr_url)
end

hathi_file = "zephir_upd_#{date}.json.gz"
logger.info("indexing HathiFile #{hathi_file}")
IndexHathi.new.perform(hathi_file, solr_url)
