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
    puts "indexing #{file}"
    system("bin/m_delete_ids #{file}")
  end
end
