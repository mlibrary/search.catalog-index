module Jobs
  module LibLocInfo
    class Libraries
      def initialize
        response = ::AlmaRestClient.client.get('/conf/libraries')
        if response.status == 200 
          @data = response.body
        else
          @data = {}
        end
      end
      def to_a
        @data["library"]&.map{|x| Library.new(x).to_h}
      end
      def to_json
        to_a.to_json
      end
      class Library
        def initialize(library)
          @library = library
        end
        def to_h
          { 
            code: @library["code"],
            info_link: description["info_link"],
            name: @library["name"]
          }
        end
        private 
        def description
          if @library["description"]
            JSON.parse(@library["description"])
          else
            {}
          end
        end
      end
    end
  end
end
