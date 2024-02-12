$:.unshift "#{File.dirname(__FILE__)}"
require "alma_rest_client"
require "sftp"
require "prometheus/client"
require "prometheus/client/push"
require "prometheus/client/registry"

require "jobs/catalog_indexing_metrics"
require "jobs/utilities"
require "jobs/utilities/alma_file_processor"
require "jobs/utilities/zephir_file"
require "jobs/utilities/translation_map_fetcher"

require "jobs/lib_loc_info/libraries"
require "jobs/lib_loc_info/library_location_list"

require "jobs/electronic_collections"

require "jobs/delete_id_getter"
require "jobs/delete_alma_ids"

require "jobs/index_alma_xml"
require "jobs/index_hathi_json"

module Jobs
end
