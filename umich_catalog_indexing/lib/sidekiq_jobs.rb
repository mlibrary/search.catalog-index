$:.unshift File.dirname(__FILE__).to_s
require "sidekiq"
require "jobs"
require "services"

class JobQueued
  def call(worker, job, queue, redis_pool)
    Faraday.post("#{ENV.fetch("SIDEKIQ_SUPERVISOR_HOST")}/api/v1/jobs", {
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
    chain.add JobQueued if ENV.fetch("SUPERVISOR_ON") == "true"
  end
end

class CheckInCheckOut
  def call(worker, job, queue)
    Faraday.post("#{ENV.fetch("SIDEKIQ_SUPERVISOR_HOST")}/api/v1/jobs/#{job["jid"]}/started", {
      arguments: job["args"].to_json,
      job_class: job["class"],
      queue: queue
    })
    yield
    Faraday.post("#{ENV.fetch("SIDEKIQ_SUPERVISOR_HOST")}/api/v1/jobs/#{job["jid"]}/complete", {
      arguments: job["args"].to_json,
      job_class: job["class"],
      queue: queue
    })
  end
end

Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add CheckInCheckOut if ENV.fetch("SUPERVISOR_ON") == "true"
  end
end

class IndexIt
  include Sidekiq::Worker
  def perform(file, solr_url)
    puts "indexing #{file} into #{solr_url}"
    metrics = Jobs::CatalogIndexingMetrics.new({type: "IndexIt", destination: solr_url})
    Jobs::IndexAlmaXml.new(file: file, solr_url: solr_url).run
    metrics.push
  rescue Jobs::CatalogIndexingMetrics::PushGatewayClientError
    puts "Error: Failed contact the Push Gateway"
  end
end

class DeleteIt
  include Sidekiq::Worker
  def perform(file, solr_url)
    puts "indexing deletes from #{file} into #{solr_url}"
    metrics = Jobs::CatalogIndexingMetrics.new({type: "DeleteIt", destination: solr_url})
    Jobs::DeleteAlmaIds.new(file: file, solr_url: solr_url).run
    metrics.push
  rescue Jobs::CatalogIndexingMetrics::PushGatewayClientError
    puts "Error: Failed contact the Push Gateway"
  end
end

class IndexHathi
  include Sidekiq::Worker
  def perform(file, solr_url)
    puts "indexing zephir #{file} into #{solr_url}"
    metrics = Jobs::CatalogIndexingMetrics.new({type: "IndexHathi", destination: solr_url})
    Jobs::IndexHathiJson.new(file: file, solr_url: solr_url).run
    metrics.push
  rescue Jobs::CatalogIndexingMetrics::PushGatewayClientError
    puts "Error: Failed contact the Push Gateway"
  end
end
