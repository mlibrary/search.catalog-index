require_relative "./jobs"
require 'logger'
require 'date'

class IndexForDate
  def initialize(alma_files:,date:,solr_url:,
                 delete_it: DeleteIt.new,
                 index_it: IndexIt.new,
                 index_hathi: IndexHathi.new,
                 logger: Logger.new($stdout)
                )
    @date = DateTime.parse(date).strftime("%Y%m%d") #must be a string in the form YYYYMMDD

    begin
      @alma_files = alma_files.select{|x| x.match?(@date)} #must be an array of file paths
    rescue NoMethodError
      raise StandardError, "alma_files must be an array of file path strings"
    end

    @solr_url = solr_url
    raise StandardError, "solr_url must be a string of the solr to index into" unless @solr_url.is_a? String
    
    @delete_it = delete_it
    @index_it = index_it
    @index_hathi = index_hathi
    @logger = logger
  end

  def run
    files_that_match(/_delete\.tar/).each do | file |
      @logger.info("deleting ids from file: #{file}")
      @delete_it.perform(file, @solr_url)
    end
    files_that_match(/_new\.tar/).each do | file |
      @logger.info("Indexing metadata from file: #{file}")
      @index_it.perform(file, @solr_url)
    end

    @logger.info("Indexing HathiTrust metadata from file: #{hathi_file}")
    @index_hathi.perform(hathi_file, @solr_url)
  end
  private
  def files_that_match(pattern)
    @alma_files.select{|x| x.match?(pattern)}
  end
  def hathi_file
    "zephir_upd_#{@date}.json.gz"
  end
end
