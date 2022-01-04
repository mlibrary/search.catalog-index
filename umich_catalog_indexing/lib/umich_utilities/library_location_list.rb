module UmichUtilities
  class LibraryLocationList
    def initialize
      libraries = Libraries.new
      @library_locations = {} 
      libraries.to_a&.each do |lib|
        resp = AlmaRestClient.client.get("/conf/libraries/#{lib[:code]}/locations")
        if resp.code == 200
          resp.parsed_response["location"]&.each do |loc|
            next if loc["code"].match?(/^\d+$/) #skip numerical locations
            libloc = Location.new(lib,loc)
            @library_locations[libloc.key] = {
              "info_link" => libloc.info_link,
              "name" => libloc.display_text
            }
          end
        end
      end
    end
    def list
      @library_locations&.sort&.to_h
    end
    class Location
      def initialize(library, location)
        @library = library
        @location = location
      end
      def library_code
        @library[:code].upcase
      end
      def location_code
        @location["code"].upcase
      end
      def info_link
        @library[:info_link] || ''
      end
      def display_text
        name = @location["external_name"] 
        name = @location["name"] if name.empty?
        name = '' if ["NONE","UNASSIGNED location", location_code].include?(name)
        name = '' if location_code.upcase == name.upcase
  
        [@library[:name], name].reject{|x| x.nil? or x == ''}.join(' ').strip
      end
      def key
        [library_code, location_code].join(" ")
      end
      def to_h
        {
          key: key,
          library_code: library_code,
          location_code: location_code,
          info_link: info_link,
          display_text: display_text,
        }
      end
    end
  end
end
