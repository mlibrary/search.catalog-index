#require_relative "./alma_file_processor"
#require_relative './umich_utilities/umich_utilities'
require "high_level_browse"

module Jobs
  class IndexAlmaXml
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
      @logger.info "fetching high level browse file"
      fetch_high_level_browse
      @logger.info "fetching library and location info"
      fetch_lib_loc_info
      @logger.info "starting traject process for #{@alma_file_processor.xml_file}"
      run_traject(@alma_file_processor.xml_file)
      @logger.info "finished loading marc data from #{@alma_file_processor.xml_file} into #{@solr_url}"
      @logger.info "cleaning scratch directory"
      @alma_file_processor.clean
      @logger.info "finished processing #{@file}"
    end
    def fetch_high_level_browse
      if should_fetch?(hlb_file) 
        HighLevelBrowse.fetch_and_save(dir: hlb_dir)
        @logger.info "updated #{hlb_file}"
      else
        @logger.info "#{hlb_file} is less than one day old. Did not update"
      end
    end
    def fetch_lib_loc_info
      if should_fetch?(lib_loc_info_file)
        temporary_path = "#{lib_loc_info_file}.temporary"
        File.open(temporary_path, 'w'){|f| f.write Jobs::LibLocInfo::LibraryLocationList.new.list.to_yaml(line_width: 1000 ) }
        if !File.exists?(temporary_path) || File.size?(temporary_path) < 15
          @logger.error "Did not update #{lib_loc_info_file}. Failed to load file"
        else
          File.rename(temporary_path, lib_loc_info_file)
          @logger.info "updated #{lib_loc_info_file}"
        end
      else
        @logger.info "#{lib_loc_info_file} is less than one day old. Did not update"
      end
    end
    def run_traject(file)
      system( "bundle", "exec", "traject",
             "-c", "/app/readers/m4j.rb",
             "-c", "/app/writers/solr.rb",
             "-c", "/app/indexers/settings.rb",
             "-c", "/app/indexers/common.rb",
             "-c", "/app/indexers/common_ht.rb",
             "-c", "/app/indexers/subject_topic.rb",
             "-c", "/app/indexers/umich.rb",
             "-c", "/app/indexers/umich_alma.rb",
             "-u", @solr_url,
             file
      )
    end
    private
    def should_fetch?(file)
      #true when file doesn't exit or if file is older than a day
      !File.exists?(file) or 
        File.stat(file).mtime < Time.now - (60*60*24) 
    end
    def hlb_dir
      "/app/lib/translation_maps"
    end
    def hlb_file
      "#{hlb_dir}/hlb.json.gz"
    end
    def lib_loc_info_file
      "/app/lib/translation_maps/umich/libLocInfo.yaml"
    end
  end
end
