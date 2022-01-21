require 'sidekiq'
class IndexIt
  include Sidekiq::Worker
  def perform(file)
    puts "indexing #{file}"
    system("bin/mindex_xml #{file}")
  end
end
