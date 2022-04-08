require 'sidekiq'
class IndexIt
  include Sidekiq::Worker
  def perform(file, solr_url)
    puts "indexing #{file} into #{solr_url}"
    system("bin/mindex_xml #{file} #{solr_url}")
  end
end
class DeleteIt
  include Sidekiq::Worker
  def perform(file, solr_url)
    puts "indexing deletes from #{file} into #{solr_url}"
    system("bin/m_delete_ids #{file} #{solr_url}")
  end
end
class IndexHathi
  def perform(file, solr_url)
    puts "indexing zephir #{file} into #{solr_url}"
    system("bin/mindex_hathi #{file} #{solr_url}")
  end
end
