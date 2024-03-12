#!/usr/local/bin/ruby
require "date"
require_relative "../lib/sidekiq_jobs"
require "logger"

logger = S.logger
logger.info "Starting submission of HathiTrust monthly full job"

zephir_file = Jobs::Utilities::ZephirFile.latest_monthly_full
zephir_file_basename = zephir_file.split(".").first

files = SFTP.client.ls("production/zephir_full/#{zephir_file_basename}_*"

files.each do |file|
  logger.info "Sending job to index #{file} into reindex solr: #{ENV.fetch("REINDEX_SOLR_URL")}"
  IndexJson.set(queue: 'reindex').perform_async(file, ENV.fetch("REINDEX_SOLR_URL"))
end

logger.info "Finished submitting HathiTrust monthly full job"
