#!/usr/local/bin/ruby

require "date"
require_relative "../lib/sidekiq_jobs"
require "logger"

logger = Logger.new($stdout)
logger.info "Starting submission of HathiTrust daily update jobs"

hathi_file = Jobs::Utilities::ZephirFile.latest_daily_update

if ENV.fetch("SOLRCLOUD_ON") 
  logger.info "Sending job to index #{hathi_file} into hatcher production solr: #{ENV.fetch("LIVE_SOLR_URL")}"
  IndexHathi.perform_async(hathi_file, ENV.fetch("LIVE_SOLR_URL"))
else
  logger.info "Sending job to index #{hathi_file} into hatcher production solr: #{ENV.fetch("HATCHER_PRODUCTION_SOLR_URL")}"
  IndexHathi.perform_async(hathi_file, ENV.fetch("HATCHER_PRODUCTION_SOLR_URL"))
  
  logger.info "Sending job to index #{hathi_file} into macc production solr: #{ENV.fetch("MACC_PRODUCTION_SOLR_URL")}"
  IndexHathi.perform_async(hathi_file, ENV.fetch("MACC_PRODUCTION_SOLR_URL"))
end

logger.info "Finished submission of HathiTrust daily update jobs"
