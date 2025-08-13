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
    ENV.fetch("PRODUCTION_SOLR_URLS").split(",").each do |solr_url|
      logger.info "Sending job to index #{file} into #{solr_url}"
      IndexJson.perform_async(file, solr_url)
    end
  end
end

logger.info "Finished submission of HathiTrust daily update jobs"
