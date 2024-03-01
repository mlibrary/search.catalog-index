require "canister"
require "semantic_logger"

Services = Canister.new
S = Services

# When splitting MARC records from zephir into smaller files, how many records should each file have?
S.register(:marc_record_batch_size) { ENV.fetch("MARC_RECORD_BATCH_SIZE", 200_000) }

S.register(:subject_heading_remediation_set_id) { ENV["SUBJECT_HEADING_REMEDIATION_SET_ID"] }

require_relative "services/paths"
require_relative "services/logger"
require_relative "services/dbs"
require_relative "services/solr"
require_relative "services/sftp"
