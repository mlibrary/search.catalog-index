$:.unshift "#{File.dirname(__FILE__)}"
require "alma_rest_client"
require "sftp"
require "yaml"
require "prometheus/client"
require "prometheus/client/push"
require "prometheus/client/registry"

require "services"

require "jobs/catalog_indexing_metrics"
require "jobs/utilities"
require "jobs/translation_map_generator"
require "jobs/delete_id_getter"
require "jobs/delete_alma_ids"
require "jobs/index_alma_xml"
require "jobs/index_hathi_json"

module Jobs
end
