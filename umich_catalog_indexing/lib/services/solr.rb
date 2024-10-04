S.register(:solrcloud_on?) { ENV["SOLRCLOUD_ON"] == "true" }
S.register(:solr_threads) { ENV.fetch("SOLR_THREADS", 1).to_i }
S.register(:solr_user) { ENV.fetch("SOLR_USER", "solr") }
S.register(:solr_password) { ENV.fetch("SOLR_PASSWORD", "SolrRocks") }
S.register(:processing_threads) { ENV.fetch("PROCESSING_THREADS", 1) }
S.register(:supervisor_on?) { ENV["SUPERVISOR_ON"] == "true" }
S.register(:sidekiq_supervisor_host) { ENV.fetch("SIDEKIQ_SUPERVISOR_HOST", "http://supervisor:3000") }
