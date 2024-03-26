#!/usr/local/bin/ruby
$LOAD_PATH << "/app/lib"
require "sidekiq_jobs"
if ["-h","--help"].include?(ARGV[0])
  puts <<-USAGE
description: indexes a `json.gz` file of marc records; needs `docker compose up`
usage: bundle exec index_sample.rb [file_basename]
  file_basename: sftp/search_daily_bibs/[file_basename].json.gz to be indexed.
    If not provided uses sftp/search_daily_bibs/zephir_pd_20220301.json.gz
  USAGE
  return
end
basename = ARGV[0] || "zephir_upd_20220301"
IndexJson.new.perform("search_daily_bibs/#{basename}.json.gz", "http://solr:8983/solr/biblio")
