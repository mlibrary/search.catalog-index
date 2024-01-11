$:.unshift "#{File.dirname(__FILE__)}/../lib"
require "traject"
require "marc_reader_fix"
settings do
  provide "marc_source.type", "xml"
  provide "marc_reader.ignore_namespace", true
  provide "reader_class_name", "Traject::MarcReaderFix"
end
