#require_relative "./alma_file_processor"
#require_relative './umich_utilities/umich_utilities'
require "high_level_browse"

module Jobs
  class IndexAlmaXml
    def initialize(file:,solr_url:, logger: Logger.new($stdout), 
                   translation_map_fetcher: Jobs::Utilities::TranslationMapFetcher.new,
                   alma_file_processor: Jobs::Utilities::AlmaFileProcessor.new(path: file))
      @file = file
      @logger = logger
      @solr_url = solr_url
      @alma_file_processor = alma_file_processor
      @translation_map_fetcher = translation_map_fetcher
    end
    def run
      @logger.info "fetching #{@file} from #{ENV.fetch("ALMA_FILES_HOST")}"
      @alma_file_processor.run

      @translation_map_fetcher.run

      @logger.info "starting traject process for #{@alma_file_processor.xml_file}"
      begin
        run_traject(@alma_file_processor.xml_file)
      rescue StandardError
        @logger.error "Traject step Failed"
        @logger.info "cleaning scratch directory: #{@alma_file_processor.scratch_dir}"
        @alma_file_processor.clean
        raise StandardError, "Traject step failed"
      end
      @logger.info "finished loading marc data from #{@alma_file_processor.xml_file} into #{@solr_url}"
      @logger.info "cleaning scratch directory: #{@alma_file_processor.scratch_dir}"
      @alma_file_processor.clean
      @logger.info "finished processing #{@file}"
    end
    def run_traject(file)
      if ENV.fetch("ASSESS")
        success = system( "bundle", "exec", "traject",
               "-c", "/app/readers/m4j.rb",
               "-c", "/app/writers/null.rb",
               "-c", "/app/indexers/settings.rb",
               "-c", "/app/indexers/common.rb",
               "-c", "/app/indexers/umich_alma.rb",
               file
        )
      else
        success = system( "bundle", "exec", "traject",
               "-c", "/app/readers/m4j.rb",
               "-c", "/app/writers/solr.rb",
               "-c", "/app/indexers/settings.rb",
               "-c", "/app/indexers/common.rb",
               "-c", "/app/indexers/common_ht.rb",
               "-c", "/app/indexers/subject_topic.rb",
               "-c", "/app/indexers/umich.rb",
               "-c", "/app/indexers/umich_alma.rb",
               "-c", "/app/indexers/callnumbers.rb",
               "-u", @solr_url,
               file
        )
      end
      raise StandardError unless success
    end
  end
end
