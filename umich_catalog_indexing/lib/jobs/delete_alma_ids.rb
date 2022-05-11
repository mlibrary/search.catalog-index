module Jobs
  class DeleteAlmaIds
    def initialize(file:,solr_url:, logger: Logger.new($stdout),
                   alma_file_processor: Jobs::Utilities::AlmaFileProcessor.new(path: file))
      @file = file
      @logger = logger
      @solr_url = solr_url
      @alma_file_processor = alma_file_processor
    end
    def run
      @logger.info "fetching #{@file} from #{ENV.fetch("ALMA_FILES_HOST")}"
      @alma_file_processor.run
      @logger.info "deleting ids in #{@file} from #{@solr_url}"
      begin
        DeleteIdGetter.new(@alma_file_processor.xml_file, @solr_url).send 
      rescue StandardError => e
        @logger.error e.message
        @logger.info "cleaning scratch directory: #{@alma_file_processor.scratch_dir}"
        @alma_file_processor.clean
        raise StandardError, e.message
      end
      @logger.info "cleaning scratch directory"
      @alma_file_processor.clean
      @logger.info "finished processing #{@file}"
    end
  end
end
