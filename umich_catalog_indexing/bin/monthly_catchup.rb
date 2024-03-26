#!/usr/local/bin/ruby

require "optparse"
require "optparse/date"
require 'logger'
require 'date'
require_relative "../lib/sidekiq_jobs"
require_relative "../lib/index_for_date"

logger = S.logger
today = Date.today
start_date = Date.new(today.year, today.month, 1) 
solr_url = ENV.fetch("REINDEX_SOLR_URL") 
path = ENV.fetch("DAILY_ALMA_FILES_PATH")

alma_files = SFTP.client.ls(path)

start_date.upto(today) do |date|
  date_string = date.strftime("%Y%m%d")
  logger.info "========================"
  logger.info "Indexing #{date_string}"
  logger.info "========================"
  IndexForDate.new(alma_files: alma_files, date: date_string, solr_url: solr_url).run
end

