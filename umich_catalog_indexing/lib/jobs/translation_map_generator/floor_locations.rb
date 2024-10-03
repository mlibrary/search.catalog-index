require "googleauth"
require "google/apis/sheets_v4"

module Jobs
  module TranslationMapGenerator
    module FloorLocations
      class << self
        include FileWriter
        # @returns [String] name of the translation map
        def name
          "Floor Locations"
        end

        # @returns [String] where in the translation map directory the file
        # should go
        def file_path
          File.join("umich", "floor_locations.json")
        end

        # @returns [String] YAML string of translation map
        def generate
          fetch.to_json
        end

        def fetch
          client = Google::Apis::SheetsV4::SheetsService.new
          scope = "https://www.googleapis.com/auth/spreadsheets.readonly"
          authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
            json_key_io: StringIO.new(S.google_api_credentials),
            scope: scope
          )
          client.authorization = authorizer
          range = "Sheet1!A2:G100"
          data = client.get_spreadsheet_values(S.floor_location_spreadsheet_id, range).values
          _generate_data_structure(data)
        end

        def _generate_data_structure(data)
          output = {}
          data.each do |row|
            next if row[0].nil?
            fl = FloorLocation.new(row)
            output[fl.library] ||= {fl.location => []}
            output[fl.library][fl.location] ||= []
            output[fl.library][fl.location].push(fl.to_h)
          end
          output
        end
      end

      class FloorLocation
        attr_reader :library, :location, :text, :code
        def initialize(data)
          @library = data[0].strip
          @location = data[1].strip
          @call_number_range = _clean_call_number_range(data[2])
          @code = data[5].strip
          @text = data[6].strip
          @data = data
        end

        def start
          return nil if type == "Everything"

          cn = @call_number_range[0]
          return cn.to_f if type == "Dewey"

          if _music_match?(cn)
            cn = _music_call_number(cn)
          elsif _asia_match?(cn)
            cn = _asia_call_number(cn)
          elsif _number_ending?(cn)
            cn = _number_ending_call_number(cn)
          end
          cn.gsub(/\s+/, "")
        end

        def stop
          return nil if type == "Everything"

          cn = @call_number_range[1] || @call_number_range[0]
          return (cn + ".9999").to_f if type == "Dewey"

          if _music_match?(cn)
            cn = _music_call_number(cn)
          elsif _asia_match?(cn)
            cn = _asia_call_number(cn)
          elsif _number_ending?(cn)
            cn = _number_ending_call_number(cn)
          end

          (cn + "z").gsub(/\s+/, "")
        end

        def type
          if @call_number_range.empty?
            "Everything"
          elsif @call_number_range[0].match?(/^\d/)
            "Dewey"
          else
            "LC"
          end
        end

        def to_h
          {
            "library" => library,
            "collection" => location,
            "start" => start,
            "stop" => stop,
            "floor_key" => code,
            "text" => text,
            "type" => type
          }
        end

        def _clean_call_number_range(str)
          str.downcase.split(/\s+-\s+/).map { |x| x.strip }
        end

        def _music_match?(cn)
          library == "MUSIC" && cn.match?(/^m/)
        end

        def _music_call_number(cn)
          parts = cn.split(/\s+/)
          "#{parts[0]}000#{parts[1]}.00000#{parts[2]}"
        end

        def _asia_match?(cn)
          location == "ASIA" && cn.match?(".")
        end

        def _asia_call_number(cn)
          parts = cn.split(/\s+/)
          "#{parts[0]}0#{parts[1]}000"
        end

        def _number_ending?(cn)
          cn.match?(/\d$/)
        end

        def _number_ending_call_number(cn)
          cn + ".00000"
        end
      end
    end
  end
end
