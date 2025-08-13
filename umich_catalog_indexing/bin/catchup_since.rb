#!/usr/local/bin/ruby

require "optparse"
require "optparse/date"
require 'date'
require_relative "../lib/sidekiq_jobs"
require_relative "../lib/index_alma_for_date"
require_relative "../lib/index_zephir_for_date"

logger = S.logger

today = Date.today
start_date = Date.new(today.year, today.month, 1) #First of the month

solr_url = ENV.fetch("REINDEX_SOLR_URL") 
alma_path = ENV.fetch("DAILY_ALMA_FILES_PATH")
zephir_path = "production/zephir_daily"

opt_parser = OptionParser.new do |opts|
  opts.banner = "Usage: catchup_alma_since.rb [options] alma||zephir||both"
  opts.on("-d", "--date=DATE", Date, "Date from which to catchup from. Default is the first of the current month") do |x|
    raise ArgumentError, "date must be today or earlier" if x > Date.today
    start_date = x
  end
  opts.on("-sSOLR", "--solr=SOLR", "Solr url to index into; must provide a valid url; Default: #{solr_url}") do |url|
    raise ArgumentError, "solr must be a valid url" unless url =~ /^#{URI::regexp(%w(http https))}$/ 
    solr_url = url
  end


  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end
end.parse!

if ARGV.empty? || !(["alma","zephir", "both" ].include?(ARGV[0]) )
  puts optparse
  exit(-1)
end

repo = ARGV[0]
if ["both","alma"].include?(repo)
  repository = "alma" 
  dir = alma_path
  file_paths = SFTP.client.ls(dir)
  start_date.upto(DateTime.now) do |date|
    date_string = date.strftime("%Y%m%d")
    logger.info "========================"
    logger.info "Indexing #{repository.capitalize} #{date_string}"
    logger.info "========================"
    Object.const_get("Index#{repository.capitalize}ForDate").new(file_paths: file_paths, date: date_string, solr_url: solr_url).run
  end
end

if ["both","zephir"].include?(repo)
  repository = "zephir"
  dir = zephir_path
  file_paths = SFTP.client.ls(dir)
  zephir_start = start_date - 1
  zephir_start.upto(DateTime.now - 1) do |date|
    date_string = date.strftime("%Y%m%d")
    logger.info "========================"
    logger.info "Indexing #{repository.capitalize} #{date_string}"
    logger.info "========================"
    Object.const_get("Index#{repository.capitalize}ForDate").new(file_paths: file_paths, date: date_string, solr_url: solr_url).run
  end
end
