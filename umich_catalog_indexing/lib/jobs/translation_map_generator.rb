module Jobs
  module TranslationMapGenerator
    def self.all
      [
        HighLevelBrowse,
        ElectronicCollections,
        LibLocInfo
      ]
    end

    module FileWriter
      # Mixin for writing the translation map to given the file path. This method expects the class method .generate_translation_map
      # @param path [String] path to location to write the file
      def write_to_file(path)
        File.write(path, generate)
      end
    end
  end
end

require_relative "translation_map_generator/electronic_collections"
require_relative "translation_map_generator/lib_loc_info"
require_relative "translation_map_generator/high_level_browse"
