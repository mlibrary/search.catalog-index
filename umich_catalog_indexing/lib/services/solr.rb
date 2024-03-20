S.register(:solrcloud_on?) do
  (ENV["SOLRCLOUD_ON"] == "true") ? true : false
end
S.register(:solr_threads) { ENV.fetch("SOLR_THREADS", 1).to_i }
S.register(:solr_user) { ENV.fetch("SOLR_USER", "solr") }
S.register(:solr_password) { ENV.fetch("SOLR_PASSWORD", "SolrRocks") }
S.register(:processing_threads) { ENV.fetch("PROCESSING_THREADS", 8) }
