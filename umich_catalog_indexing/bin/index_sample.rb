#!/usr/local/bin/ruby
$LOAD_PATH << "/app/lib"
require "sidekiq_jobs"
if ["-h","--help"].include?(ARGV[0])
  puts <<-USAGE
description: indexes a `tar.gz` file of Alma marc records; needs `docker-compose up`
usage: bundle exec index_sample.rb [file_basename]
  file_basename: sftp/search_daily_bibs/[file_basename].tar.gz to be indexed.
                 If not provided uses sftp/search_daily_bibs/sample.tar.gz
  USAGE
  return
end
basename = ARGV[0] || "sample"
IndexIt.new.perform("search_daily_bibs/#{basename}.tar.gz", "http://solr:8983/solr/biblio")
