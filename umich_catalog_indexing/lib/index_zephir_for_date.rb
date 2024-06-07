require "date"
require_relative "sidekiq_jobs"

class IndexZephirForDate
  def initialize(file_paths:, date:, solr_url:,
    index_json: IndexJson.new)

    @date = DateTime.parse(date) # must be a string in the form YYYYMMDD

    begin
      @file_paths = file_paths.select { |x| x.match?(date_string(@date)) } # must be an array of file paths
    rescue NoMethodError => e
      raise StandardError, "file_paths must be an array of file path strings; #{e.message}"
    end

    @solr_url = solr_url
    raise StandardError, "solr_url must be a string of the solr to index into" unless @solr_url.is_a? String

    @index_json = index_json
  end

  def run
    @file_paths.each do |file|
      S.logger.info("-------")
      S.logger.info("Indexing HathiTrust Metadata from file: #{file}")
      S.logger.info("-------")
      @index_json.perform(file, @solr_url)
      S.logger.info("-------")
      S.logger.info("Finished Indexing HathiTrust Metadata from file: #{file}")
      S.logger.info("-------")
    end
  end

  def date_string(date)
    date.strftime("%Y%m%d") # must be a string in the form YYYYMMDD
  end
end
