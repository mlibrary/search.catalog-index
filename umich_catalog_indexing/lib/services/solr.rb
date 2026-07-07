S.register(:solrcloud_on?) { ENV["SOLRCLOUD_ON"] == "true" }
S.register(:solr_threads) { ENV.fetch("SOLR_THREADS", 1).to_i }
S.register(:solr_user) { ENV.fetch("SOLR_USER", "solr") }
S.register(:solr_password) { ENV.fetch("SOLR_PASSWORD", "SolrRocks") }
S.register(:processing_threads) { ENV.fetch("PROCESSING_THREADS", 1) }
S.register(:supervisor_on?) { ENV["SUPERVISOR_ON"] == "true" }
S.register(:sidekiq_supervisor_host) { ENV.fetch("SIDEKIQ_SUPERVISOR_HOST", "http://supervisor:3000") }
S.register(:reindex_solr_url) { ENV.fetch("REINDEX_SOLR_URL", "http://solr:8983/solr/biblio") }
S.register(:production_solr_urls) { ENV.fetch("PRODUCTION_SOLR_URLS", "http://solr:8983/solr/biblio").split(",") }
S.register(:live_solr_url) { ENV.fetch("LIVE_SOLR_URL", "http://solr:8983/solr/biblio") }
