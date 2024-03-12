require "high_level_browse"

module Jobs
  class IndexJson
    def initialize(file:, solr_url:, logger: S.logger,
      translation_map_generator: TranslationMapGenerator,
      file_processor: Jobs::Utilities::FileProcessor.new(remote_path: file))
      @file = file
      @logger = logger
      @solr_url = solr_url
      @file_processor = file_processor
      @translation_map_generator = translation_map_generator
    end

    def run
      @logger.info "fetching #{@file} from #{ENV.fetch("ALMA_FILES_HOST")}"
      @file_processor.run

      @translation_map_generator.generate_all

      @logger.info "starting traject process for #{@file_processor.local_file}"
      begin
        run_traject(@file_processor.local_file)
      rescue
        @logger.error "Traject step Failed"
        @logger.info "cleaning scratch directory: #{@file_processor.scratch_dir}"
        @file_processor.clean
        raise StandardError, "Traject step failed"
      end
      @logger.info "finished loading marc data from #{@file_processor.local_file} into #{@solr_url}"
      @logger.info "cleaning scratch directory: #{@file_processor.scratch_dir}"
      @file_processor.clean
      @logger.info "finished processing #{@file}"
    end

    def run_traject(file)
      success = system("bundle", "exec", "traject",
        "-c", "/app/readers/ndj.rb",
        "-c", "/app/writers/solr.rb",
        "-c", "/app/indexers/settings.rb",
        "-c", "/app/indexers/common.rb",
        "-c", "/app/indexers/common_ht.rb",
        "-c", "/app/indexers/subject_topic.rb",
        "-c", "/app/indexers/umich.rb",
        "-c", "/app/indexers/umich_alma.rb",
        "-c", "/app/indexers/callnumbers.rb",
        "-u", @solr_url,
        file)
      raise StandardError unless success
    end
  end
end
