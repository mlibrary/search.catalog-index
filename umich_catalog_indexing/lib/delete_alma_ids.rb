require 'httparty'
require 'marc'
require 'httpclient'
require_relative "./alma_file_processor"

class DeleteIdGetter
  attr_reader :ids
  def initialize(xml_file, solr_url, logger=Logger.new($stdout))
    @logger = logger
    @url = "#{solr_url}/update"
    reader = MARC::XMLReader.new(xml_file)
    @ids = []
    reader.each{ |record| @ids << record['001'].value }
  end
  def body
    body = "<delete>"
    @ids.each do |id|
      body << "<id>#{id.chomp}</id>"
    end
    body << "</delete>"
    body
  end
  def send
    response = HTTParty.post(@url, body: body, headers: { 'Content-Type' => 'text/xml' }, query: { commit: true })
    @logger.info response.body
  end
end

class DeleteAlmaIds
  def initialize(file:,solr_url:, logger: Logger.new($stdout),
                 alma_file_processor: AlmaFileProcessor.new(path: file))
    @file = file
    @logger = logger
    @solr_url = solr_url
    @alma_file_processor = alma_file_processor
  end
  def run
    @logger.info "fetching #{@file} from #{ENV.fetch("ALMA_FILES_HOST")}"
    @alma_file_processor.run
    @logger.info "deleting ids in #{@file} from #{@solr_url}"
    DeleteIdGetter.new(@alma_file_processor.xml_file, @solr_url).send 
    @logger.info "cleaning scratch directory"
    @alma_file_processor.clean
    @logger.info "finished processing #{@file}"
  end
end
