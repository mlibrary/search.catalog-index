#!/usr/local/bin/ruby
#
require "date"
require_relative "../lib/sidekiq_jobs"
require "logger"

logger = Logger.new($stdout)
logger.info "Starting submitting HathiTrust daily update jobs"

date = DateTime.now.prev_day.strftime("%Y%m%d")
hathi_file = "zephir_upd_#{date}.json.gz"

logger.info "Sending job to index #{hathi_file} into hatcher production solr: #{ENV.fetch("HATCHER_PRODUCTION_SOLR_URL")}"

IndexHathi.perform_async(hathi_file, ENV.fetch("MACC_PRODUCTION_SOLR_URL"))

logger.info "Sending job to index #{hathi_file} into macc production solr: #{ENV.fetch("MACC_PRODUCTION_SOLR_URL")}"
IndexHathi.perform_async(hathi_file, ENV.fetch("MACC_PRODUCTION_SOLR_URL"))

logger.info "Finished submitting HathiTrust daily update jobs"
