require "date"
require_relative "sidekiq_jobs"

class IndexAlmaForDate
  def initialize(file_paths:, date:, solr_url:,
    delete_it: DeleteIt.new,
    index_it: IndexIt.new)
    @date = DateTime.parse(date) # must be a string in the form YYYYMMDD

    begin
      @file_paths = file_paths.select { |x| x.match?(date_string(@date)) } # must be an array of file paths
    rescue NoMethodError
      raise StandardError, "file_paths must be an array of file path strings"
    end

    @solr_url = solr_url
    raise StandardError, "solr_url must be a string of the solr to index into" unless @solr_url.is_a? String

    @delete_it = delete_it
    @index_it = index_it
    @logger = S.logger
  end

  def run
    @logger.info("Indexing Alma Medata")
    files_that_match(/_delete_?\d?\d?\.tar/).each do |file|
      @logger.info("deleting ids from file: #{file}")
      @delete_it.perform(file, @solr_url)
    end
    files_that_match(/_new_?\d?\d?\.tar/).each do |file|
      @logger.info("Indexing metadata from file: #{file}")
      @index_it.perform(file, @solr_url)
    end
  end

  private

  def files_that_match(pattern)
    @file_paths.select { |x| x.match?(pattern) }
  end

  def date_string(date)
    date.strftime("%Y%m%d") # must be a string in the form YYYYMMDD
  end
end
