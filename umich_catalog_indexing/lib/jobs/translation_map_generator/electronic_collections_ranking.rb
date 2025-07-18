require "googleauth"
require "google/apis/sheets_v4"

module Jobs
  module TranslationMapGenerator
    module ElectronicCollectionsRanking
      class << self
        include FileWriter
        # @returns [String] name of the translation map
        def name
          "Electronic Collections Ranking"
        end

        # @returns [String] where in the translation map directory the file
        # should go
        def file_path
          File.join("umich", "electronic_collections_ranking.yaml")
        end

        # @returns [String] YAML string of translation map
        def generate
          fetch.to_yaml(line_width: 1000)
        end

        def fetch
          client = Google::Apis::SheetsV4::SheetsService.new
          scope = "https://www.googleapis.com/auth/spreadsheets.readonly"
          authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
            json_key_io: StringIO.new(S.google_api_credentials),
            scope: scope
          )
          client.authorization = authorizer
          range = "Data!A2:G7000"
          data = client.get_spreadsheet_values(S.electronic_collections_ranking_spreadsheet_id, range).values
          _generate_data_structure(data)
        end

        def _generate_data_structure(data)
          result = {}
          data.each do |row|
            next if row[0].nil? || row[0] == "None"
            ec = ElectronicCollection.new(row)
            result[ec.collection_id] = {
              "ranking" => ec.ranking,
              "collection_name" => ec.name
            }
          end
          result
        end
      end

      class ElectronicCollection
        attr_reader :collection_id, :ranking, :name
        def initialize(data)
          @collection_id = data[0].strip
          @name = data[4].strip
          @ranking = data[6].strip
        rescue => e
          S.logger.error("ROW: #{data}; ERROR: #{e}")
        end
      end
    end
  end
end
