class Traject::MarcReaderFix
  include Enumerable

  attr_reader :settings, :input_stream

  @@best_xml_parser = MARC::XMLReader.best_available

  def initialize(input_stream, settings)
    @settings = Traject::Indexer::Settings.new settings
    @input_stream = input_stream
  end

  # Creates proper kind of ruby MARC reader, depending
  # on settings or guesses.
  def internal_reader
    unless defined? @internal_reader
      @internal_reader =
        case settings["marc_source.type"]
        when "xml"
          args = {}
          args[:parser] = settings["marc_reader.xml_parser"] || @@best_xml_parser
          args[:ignore_namespace] = settings["marc_reader.ignore_namespace"] || false
          MARC::XMLReader.new(input_stream, **args)
        when "json"
          Traject::NDJReader.new(input_stream, settings)
        else
          args = {invalid: :replace}
          args[:external_encoding] = settings["marc_source.encoding"]
          MARC::Reader.new(input_stream, args)
        end
    end
    @internal_reader
  end

  def each(...)
    internal_reader.each(...)
  end
end
