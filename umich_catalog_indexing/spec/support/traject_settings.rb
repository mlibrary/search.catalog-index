$:.unshift "#{File.dirname(__FILE__)}/../lib"
require "library_stdnums"

require "traject/macros/marc21"
extend Traject::Macros::Marc21

require "traject/macros/marc21_semantics"
extend Traject::Macros::Marc21Semantics

require "traject/macros/marc_format_classifier"
extend Traject::Macros::MarcFormats

require "ht_traject"
extend HathiTrust::Traject::Macros
extend Traject::UMichFormat::Macros

require "traject/null_writer"

require "marc_record_speed_monkeypatch"
require "marc4j_fix"

UmichOverlap = if ENV["NODB"]
  require "ht_traject/no_db_mocks/ht_overlap"
  HathiTrust::NoDB::UmichOverlap
else
  require "ht_traject/ht_overlap"
  HathiTrust::UmichOverlap
end

settings do
  store "writer_class_name", "Traject::NullWriter"
  store "log.level", "error"
end

each_record HathiTrust::Traject::Macros.setup
