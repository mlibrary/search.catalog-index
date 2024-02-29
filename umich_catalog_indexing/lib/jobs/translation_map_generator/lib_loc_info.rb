require_relative "lib_loc_info/libraries"
require_relative "lib_loc_info/library_location_list"

module Jobs
  module TranslationMapGenerator
    module LibLocInfo
      class << self
        include FileWriter
        # @returns [String] name of the translation map
        def name
          "Library and Location Information"
        end

        # @returns [String] where in the translation map directory the file
        # should go
        def file_path
          File.join("umich", "libLocInfo.yaml")
        end

        # @returns [String] YAML string of translation map
        def generate
          LibraryLocationList.new.list.to_yaml(line_width: 1000)
        end
      end
    end
  end
end
