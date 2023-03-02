#!/usr/local/bin/ruby
$LOAD_PATH << "/app/lib"
require "sidekiq_jobs"
IndexIt.perform_async("search_daily_bibs/sample.tar.gz", "http://solr:8026/solr/biblio")
