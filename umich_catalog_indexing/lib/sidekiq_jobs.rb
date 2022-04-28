require "sidekiq"
require "/app/lib/jobs"
class IndexIt
  include Sidekiq::Worker
  def perform(file, solr_url)
    puts "indexing #{file} into #{solr_url}"
    Jobs::IndexAlmaXml.new(file: file, solr_url: solr_url).run
  end
end
class DeleteIt
  include Sidekiq::Worker
  def perform(file, solr_url)
    puts "indexing deletes from #{file} into #{solr_url}"
    Jobs::DeleteAlmaIds.new(file: file, solr_url: solr_url).run
  end
end
class IndexHathi
  include Sidekiq::Worker
  def perform(file, solr_url)
    puts "indexing zephir #{file} into #{solr_url}"
    Jobs::IndexHathiJson.new(file: file, solr_url: solr_url).run
  end
end
