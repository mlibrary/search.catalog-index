require "securerandom"
module Jobs
  module Utilities
    class TranslationMapFetcher
      def initialize(logger = S.logger)
        @logger = logger
      end

      def run
        @logger.info "fetching high level browse file"
        fetch_high_level_browse
        @logger.info "fetching library and location info"
        fetch_lib_loc_info
        @logger.info "fetching electronic collections info"
        fetch_electronic_collections
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
        fetch_translation_map(path: lib_loc_info_file, fetcher: lambda { Jobs::LibLocInfo::LibraryLocationList.new.list.to_yaml(line_width: 1000) })
      end

      def fetch_electronic_collections
        fetch_translation_map(path: electronic_collection_file, fetcher: lambda { Jobs::ElectronicCollections.fetch.to_yaml(line_width: 1000) })
      end

      # @param path [String] [path to where the translation map should be saved]
      # @param fetcher [[Proc]] [The block of code that generates the string to
      # be written to a file]
      def fetch_translation_map(path:, fetcher:)
        if should_fetch?(path)
          temporary_path = "#{path}_#{SecureRandom.alphanumeric(8)}.temporary"
          File.write(temporary_path, fetcher.call)
          if !File.exist?(temporary_path) || File.size?(temporary_path) < 15
            @logger.error "Did not update #{path}. Failed to load file"
          else
            File.rename(temporary_path, path)
            @logger.info "updated #{path}"
          end
        else
          @logger.info "#{path} is less than one day old. Did not update"
        end
      end

      def should_fetch?(file)
        # true when file doesn't exit or if file is older than a day
        !File.exist?(file) or
          File.stat(file).mtime < Time.now - (60 * 60 * 24)
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

      def electronic_collection_file
        "/app/lib/translation_maps/umich/electronic_collections.yaml"
      end
    end
  end
end
