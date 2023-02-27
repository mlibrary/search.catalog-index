require 'library_stdnums'

require 'traject/macros/marc21_semantics'
extend Traject::Macros::Marc21Semantics

require 'traject/macros/marc_format_classifier'
extend Traject::Macros::MarcFormats

require 'ht_traject'
extend HathiTrust::Traject::Macros
extend Traject::UMichFormat::Macros

require "traject/null_writer"


settings do
  store "writer_class_name", "Traject::NullWriter"
  store "log.level", "error"
end

# mrio: Might need this at some point?
#each_record HathiTrust::Traject::Macros.setup
