require "jobs/lib_loc_info/libraries"
require "jobs/lib_loc_info/library_location_list"

module Jobs
  module LibLocInfo
    def self.generate_translation_map
      LibraryLocationList.new.list.to_yaml(line_width: 1000)
    end
  end
end
