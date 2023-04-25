$:.unshift "#{File.dirname(__FILE__)}"
require "sidekiq"
require "yabeda/sidekiq"
require "yabeda/prometheus"
require "jobs"
require "sftp"

Yabeda.configure do
  gauge :indexing_job_last_success, comment: "Time the indexing last succeeded", tags: [:destination, :type]
end
Yabeda.configure!

class JobQueued
  def call(worker, job, queue, redis_pool)
    response = Faraday.post("#{ENV.fetch("SIDEKIQ_SUPERVISOR_HOST")}/api/v1/jobs", {
      job_id: job["jid"],
      arguments: job["args"].to_json,
      job_class: job["class"],
      queue: queue
    })
    yield
  end
end

Sidekiq.configure_client do |config|
  config.client_middleware do |chain|
    chain.add JobQueued
  end
end

class CheckInCheckOut
  def call(worker, job, queue)
    response = Faraday.post("#{ENV.fetch("SIDEKIQ_SUPERVISOR_HOST")}/api/v1/jobs/#{job["jid"]}/started", {
      arguments: job["args"].to_json,
      job_class: job["class"],
      queue: queue
    })
    yield
    response = Faraday.post("#{ENV.fetch("SIDEKIQ_SUPERVISOR_HOST")}/api/v1/jobs/#{job["jid"]}/complete", {
      arguments: job["args"].to_json,
      job_class: job["class"],
      queue: queue
    })
  end
end

Sidekiq.configure_server do |config|
  Yabeda::Prometheus::Exporter.start_metrics_server!
  config.server_middleware do |chain|
    chain.add CheckInCheckOut
  end
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
