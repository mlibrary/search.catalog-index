require "services"
require "umich_traject/building_map"
require "umich_traject/location_map"
require "umich_traject/floor_location"
require "umich_traject/lib_loc_info"

require "umich_traject/enumcron_sorter"
require "umich_traject/holdings"
require "umich_traject/digital_holding"
require "umich_traject/physical_holding"
require "umich_traject/physical_item"

UMich::FloorLocation.configure("lib/translation_maps/umich/floor_locations.json")
