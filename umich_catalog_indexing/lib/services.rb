require "canister"
require "semantic_logger"

Services = Canister.new
S = Services

# When splitting MARC records from zephir into smaller files, how many records should each file have?
S.register(:marc_record_batch_size) { ENV.fetch("MARC_RECORD_BATCH_SIZE", 200_000) }

S.register(:subject_heading_remediation_set_id) { ENV["SUBJECT_HEADING_REMEDIATION_SET_ID"] }

S.register(:app_env) { ENV["APP_ENV"] || "development" }

S.register(:google_api_credentials) { ENV["GOOGLE_API_CREDENTIALS"] || "{}" }
S.register(:floor_location_spreadsheet_id) { ENV["FLOOR_LOCATION_SPREADSHEET_ID"] || "" }
S.register(:recommended_resources_url) { ENV["RECOMMENDED_RESOURCES_URL"] || "https://ddm.dnd.lib.umich.edu/sites/default/files/journal_recommendations.json" }

require_relative "services/paths"
require_relative "services/logger"
require_relative "services/dbs"
require_relative "services/solr"
require_relative "services/sftp"
