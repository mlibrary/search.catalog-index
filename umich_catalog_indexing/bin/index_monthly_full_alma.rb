#!/usr/local/bin/ruby
require_relative "../lib/sidekiq_jobs"

logger = S.logger
logger.info "Starting submission of Alma monthly full jobs"

all_files = SFTP.client.ls("production/search_full_bibs/*")
latest_date = all_files.map do |f|
  File.basename(f).split("_")[1]
end.uniq.sort.last

files = all_files.select{|x| x.match?(latest_date) }

files.each do |file|
  logger.info "Sending job to index #{file} into reindex solr: #{ENV.fetch("REINDEX_SOLR_URL")}"
  IndexIt.set(queue: 'reindex').perform_async(file, ENV.fetch("REINDEX_SOLR_URL"))
end

logger.info "Finished submitting Alma monthly full jobs"
