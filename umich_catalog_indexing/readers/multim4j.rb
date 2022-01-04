require_relative '../lib/multifile_marc4j_reader'


# Provides a reader that transparently switches from one file to another.
# Files must (currently) come in as a single glob

settings do
  store "reader_class_name", "Traject::MultiFileMarc4JReader"
  store "marc4j_reader.keep_marc4j", true
  provide "marc_source.type", "xml"
  provide "source_glob", ENV["MARC_XML_DIR"]
end
