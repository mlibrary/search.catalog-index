require "sidekiq"
require "prometheus/client"
require "prometheus/client/push"
require "prometheus/client/registry"
require "/app/lib/jobs"

class CatalogIndexMetrics
  def initialize(labels)
    @labels = labels
    @start_time = current_timestamp
  end

  def push
    indexing_job_duration_seconds.set(current_timestamp - @start_time)
    indexing_job_last_success.set(current_timestamp)
    gateway.add(registry)
  end

  private

  def current_timestamp
    Time.now.to_i
  end

  def registry
    @registry ||= Prometheus::Client::Registry.new
  end

  def gateway
    @gateway ||= Prometheus::Client::Push.new(
      job: "catalog_index",
      gateway: ENV.fetch("PROMETHEUS_PUSH_GATEWAY"),
      grouping_key: @labels
    )
  end

  def indexing_job_last_success
    @indexing_job_last_success ||= registry.gauge(
      :indexing_job_last_success,
      docstring: "Last successful run of an indexing job"
    )
  end

  def indexing_job_duration_seconds
    @indexing_job_duration_seconds = registry.gauge(
      :indexing_job_duration_seconds,
      docstring: "Time spent running an indexing job"
    )
  end
end

class IndexIt
  include Sidekiq::Worker
  def perform(file, solr_url)
    puts "indexing #{file} into #{solr_url}"
    metrics = CatalogIndexMetrics.new({ type: "IndexIt", destination: solr_url })
    Jobs::IndexAlmaXml.new(file: file, solr_url: solr_url).run
    metrics.push
  end
end
class DeleteIt
  include Sidekiq::Worker
  def perform(file, solr_url)
    puts "indexing deletes from #{file} into #{solr_url}"
    metrics = CatalogIndexMetrics.new({ type: "DeleteIt", destination: solr_url })
    Jobs::DeleteAlmaIds.new(file: file, solr_url: solr_url).run
    metrics.push
  end
end
class IndexHathi
  include Sidekiq::Worker
  def perform(file, solr_url)
    puts "indexing zephir #{file} into #{solr_url}"
    metrics = CatalogIndexMetrics.new({ type: "IndexHathi", destination: solr_url })
    Jobs::IndexHathiJson.new(file: file, solr_url: solr_url).run
    metrics.push
  end
end
