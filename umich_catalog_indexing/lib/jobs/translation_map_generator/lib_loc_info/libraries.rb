module Jobs
  module TranslationMapGenerator
    module LibLocInfo
      class Libraries
        def initialize
          response = ::AlmaRestClient.client.get("/conf/libraries")
          @data = if response.status == 200
            response.body
          else
            {}
          end
        end

        def to_a
          @data["library"]&.map { |x| Library.new(x).to_h }
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
end
