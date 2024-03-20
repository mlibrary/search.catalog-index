$:.unshift "#{File.dirname(__FILE__)}/../lib"
require "traject"
require "traject/solr_json_writer"
require "services"

settings do
  provide "solr_writer.basic_auth_user", S.solr_user if S.solrcloud_on?
  provide "solr_writer.basic_auth_password", S.solr_password if S.solrcloud_on?
  provide "solr_writer.max_skipped", 1000
  provide "solr_writer.commit_on_close", "true"
  provide "solr_writer.thread_pool", S.solr_threads
  provide "solr_writer.batch_size", 60
  provide "writer_class_name", "Traject::SolrJsonWriter"
  store "processing_thread_pool", S.processing_threads
  provide "log.batch_size", 50_000
end
