require 'traject'
require 'traject/solr_json_writer'

settings do
  provide "solr_writer.basic_auth_user", ENV.fetch("SOLR_USER") if ENV.fetch("SOLRCLOUD_ON") == "true"
  provide "solr_writer.basic_auth_password", ENV.fetch("SOLR_PASSWORD") if ENV.fetch("SOLRCLOUD_ON") == "true"
  provide "solr_writer.max_skipped", 1000
  provide "solr_writer.commit_on_close", "true"
  provide "solr_writer.thread_pool", 2
  provide "solr_writer.batch_size", 60
  provide "writer_class_name", "Traject::SolrJsonWriter"
  store "processing_thread_pool", 4
  provide "log.batch_size", 1000
end


