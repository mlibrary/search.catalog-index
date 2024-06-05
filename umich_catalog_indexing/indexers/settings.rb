$:.unshift "#{File.dirname(__FILE__)}/../lib"
require "services"
require "set"

require "library_stdnums"

require "traject/macros/marc21_semantics"
extend Traject::Macros::Marc21Semantics

require "traject/macros/marc_format_classifier"
extend Traject::Macros::MarcFormats

require "ht_traject"
extend HathiTrust::Traject::Macros
extend Traject::UMichFormat::Macros

require "marc/fastxmlwriter"

require "marc_record_speed_monkeypatch"
require "marc4j_fix"

#########
# Preprocessing of zephir records happens outside of Traject. Assuming all goes
# well the following block can be deleted after July 1, 2024.
#########
# UmichOverlap = if S.no_db? || S.reindex?
#   require "ht_traject/no_db_mocks/ht_overlap"
#   HathiTrust::NoDB::UmichOverlap
# else
#   require "ht_traject/ht_overlap"
#   HathiTrust::UmichOverlap
# end
# logger.info "UmichOverlap Class: #{UmichOverlap}"

settings do
  store "log.batch_progress", 10_000
end

logger.info RUBY_DESCRIPTION

################################
###### Setup ###################
################################

# Set up an area in the clipboard for use storing intermediate stuff
each_record HathiTrust::Traject::Macros.setup
