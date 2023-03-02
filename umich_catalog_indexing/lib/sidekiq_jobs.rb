$:.unshift "#{File.dirname(__FILE__)}"
require "sidekiq"
require "yabeda/sidekiq"
require "yabeda/prometheus"
require "sftp"

Yabeda.configure do
  gauge :indexing_job_last_success, comment: "Time the indexing last succeeded", tags: [:destination, :type]
end
Yabeda.configure!

Sidekiq.configure_server do |_config|
  Yabeda::Prometheus::Exporter.start_metrics_server!
end

SFTP.configure do |config|
  config.user = ENV.fetch("ALMA_FILES_USER")
  config.host=ENV.fetch("ALMA_FILES_HOST")
  config.key_path=ENV.fetch("SSH_KEY_PATH")
end

class IndexIt
  include Sidekiq::Worker
  def perform(file, solr_url)
    puts "indexing #{file} into #{solr_url}"
    Jobs::IndexAlmaXml.new(file: file, solr_url: solr_url).run
    Yabeda.indexing_job_last_success.set({type: "IndexIt", destination: solr_url},Time.now.to_i) 
  end
end
class DeleteIt
  include Sidekiq::Worker
  def perform(file, solr_url)
    puts "indexing deletes from #{file} into #{solr_url}"
    Jobs::DeleteAlmaIds.new(file: file, solr_url: solr_url).run
    Yabeda.indexing_job_last_success.set({type: "DeleteIt", destination: solr_url},Time.now.to_i) 
  end
end
class IndexHathi
  include Sidekiq::Worker
  def perform(file, solr_url)
    puts "indexing zephir #{file} into #{solr_url}"
    Jobs::IndexHathiJson.new(file: file, solr_url: solr_url).run
    Yabeda.indexing_job_last_success.set({type: "IndexHathi", destination: solr_url},Time.now.to_i) 
  end
end
