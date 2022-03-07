require 'httparty'
require 'marc'
require 'httpclient'

class DeleteIdGetter
  attr_reader :ids
  def initialize(xml_file)
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
    url = ENV.fetch('SOLR_URL') + "/update"
    puts url
    #Do I need commit true? When it's not included nothing happens.
    response = HTTParty.post(url, body: body, headers: { 'Content-Type' => 'text/xml' }, query: { commit: true })
    puts response.code
    puts response
   
    #one time this worked. What isn't it?
    #dcrw bash ./bin/m_delete_ids bib_search/search_2022022506_21405138730006381_delete.tar.gz
    #dcrw bin/mindex_xml bib_search/mrio_to_be_deleted_2022030421_21173740970006381_new.tar.gz
    #HTTPClient.new.post(url, body, {'Content-Type' => 'text/xml'})

  end
end

filename = ARGV[0]
DeleteIdGetter.new(filename).send
#puts DeleteIdGetter.new(filename).ids

