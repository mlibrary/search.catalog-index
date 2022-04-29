module Jobs
  module Utilities
    class TranslationMapFetcher
      def initialize(logger=Logger.new($stdout))
        @logger = logger
      end
      def run
        @logger.info "fetching high level browse file"
        fetch_high_level_browse
        @logger.info "fetching library and location info"
        fetch_lib_loc_info
      end
      private
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
end
