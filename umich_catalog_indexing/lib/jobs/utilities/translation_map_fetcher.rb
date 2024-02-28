require "securerandom"
module Jobs
  module Utilities
    class TranslationMapFetcher
      def initialize(
        high_level_browse_klass: HighLevelBrowse,
        translation_map_generators: [
          Jobs::TranslationMapGenerator::LibLocInfo,
          Jobs::TranslationMapGenerator::ElectronicCollections
        ],
        translation_map_dir: "/app/lib/translation_maps"
      )
        @logger = S.logger
        @high_level_browse_klass = high_level_browse_klass
        @translation_map_generators = translation_map_generators
        @translation_map_dir = translation_map_dir
      end

      def run
        @logger.info "fetching high level browse file"
        fetch_high_level_browse
        @translation_map_generators.each do |klass|
          @logger.info "fetching #{klass.name}"
          fetch_translation_map(klass: klass)
        end
      end

      private

      def fetch_high_level_browse
        if should_fetch?(hlb_file)
          @high_level_browse_klass.fetch_and_save(dir: @translation_map_dir)
          @logger.info "updated #{hlb_file}"
        else
          @logger.info "#{hlb_file} is less than one day old. Did not update"
        end
      end

      # @param klass [Class] Translation Map Generater Class
      # be written to a file]
      def fetch_translation_map(klass:)
        path = File.join(@translation_map_dir, klass.file_path)
        if should_fetch?(path)
          temporary_path = "#{path}_#{SecureRandom.alphanumeric(8)}.temporary"
          File.write(temporary_path, klass.generate_translation_map)
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

      def hlb_file
        "#{@translation_map_dir}/hlb.json.gz"
      end
    end
  end
end
