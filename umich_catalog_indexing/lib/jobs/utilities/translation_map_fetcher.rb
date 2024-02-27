require "securerandom"
module Jobs
  module Utilities
    class TranslationMapFetcher
      def initialize(
        lib_loc_info_klass: Jobs::LibLocInfo,
        electronic_collections_klass: Jobs::ElectronicCollections,
        high_level_browse_klass: HighLevelBrowse,
        translation_map_dir: "/app/lib/translation_maps"
      )
        @logger = S.logger
        @lib_loc_info_klass = lib_loc_info_klass
        @electronic_collections_klass = electronic_collections_klass
        @high_level_browse_klass = high_level_browse_klass
        @translation_map_dir = translation_map_dir
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
          @high_level_browse_klass.fetch_and_save(dir: hlb_dir)
          @logger.info "updated #{hlb_file}"
        else
          @logger.info "#{hlb_file} is less than one day old. Did not update"
        end
      end

      def fetch_lib_loc_info
        fetch_translation_map(path: lib_loc_info_file, fetcher: lambda { @lib_loc_info_klass.generate_translation_map })
      end

      def fetch_electronic_collections
        fetch_translation_map(path: electronic_collection_file, fetcher: lambda { @electronic_collections_klass.generate_translation_map })
      end

      # @param path [String] [path to where the translation map should be saved]
      # @param fetcher [[Proc]] [The block of code that generates the string to
      # be written to a file]
      def fetch_translation_map(path:, fetcher:)
        if should_fetch?(path)
          temporary_path = "#{path}_#{SecureRandom.alphanumeric(8)}.temporary"
          File.write(temporary_path, fetcher.call)
          raise StandardError, "#{temporary_path} does not exist; Failed to load file" if !File.exist?(temporary_path)
          raise StandardError, "#{temporary_path} is too small; Failed to load file" if File.size?(temporary_path) < 15
          File.rename(temporary_path, path)
          @logger.info "updated #{path}"
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
        @translation_map_dir
      end

      def hlb_file
        "#{@translation_map_dir}/hlb.json.gz"
      end

      def lib_loc_info_file
        "#{@translation_map_dir}/umich/libLocInfo.yaml"
      end

      def electronic_collection_file
        "#{@translation_map_dir}/umich/electronic_collections.yaml"
      end
    end
  end
end
