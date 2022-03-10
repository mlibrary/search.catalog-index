require 'sidekiq'
class IndexIt
  include Sidekiq::Worker
  def perform(file)
    puts "indexing #{file}"
    system("bin/mindex_xml #{file}")
  end
end
class DeleteIt
  include Sidekiq::Worker
  def perform(file)
    puts "indexing deletes from #{file}"
    system("bin/m_delete_ids #{file}")
  end
end
class IndexHathi
  def perform(file)
    puts "indexing zephir #{file}"
    system("bin/mindex_hathi #{file}")
  end
end
