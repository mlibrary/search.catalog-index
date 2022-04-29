require 'httparty'
require 'marc'
module Jobs
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
end
