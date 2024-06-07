#!/usr/local/bin/ruby

require "date"
require_relative "../lib/sidekiq_jobs"
require "logger"

logger = Logger.new($stdout)
logger.info "Starting submission of HathiTrust daily update jobs"

zephir_file = Jobs::Utilities::ZephirFile.latest_daily_update
zephir_file_basename = zephir_file.split(".").first

files = SFTP.client.ls("production/zephir_daily/#{zephir_file_basename}_*")

files.each do |file|
  if ENV.fetch("SOLRCLOUD_ON") == true
    logger.info "Sending job to index #{file} into live solr: #{ENV.fetch("LIVE_SOLR_URL")}"
    IndexJson.perform_async(file, ENV.fetch("LIVE_SOLR_URL"))
  else
    logger.info "Sending job to index #{file} into hatcher production solr: #{ENV.fetch("HATCHER_PRODUCTION_SOLR_URL")}"
    IndexJson.perform_async(file, ENV.fetch("HATCHER_PRODUCTION_SOLR_URL"))
    
    logger.info "Sending job to index #{file} into macc production solr: #{ENV.fetch("MACC_PRODUCTION_SOLR_URL")}"
    IndexJson.perform_async(file, ENV.fetch("MACC_PRODUCTION_SOLR_URL"))
  end
end

logger.info "Finished submission of HathiTrust daily update jobs"
