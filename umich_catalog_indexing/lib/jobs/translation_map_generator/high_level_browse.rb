require "zlib"
require "json"

module Jobs
  module TranslationMapGenerator
    module HighLevelBrowse
      class << self
        def file_path
          "hlb.json.gz"
        end

        def name
          "High Level Browse"
        end

        def generate_translation_map
          db = ::HighLevelBrowse.fetch
          JSON.fast_generate(db.instance_variable_get(:@all))
        end

        def write_to_file(path)
          Zlib::GzipWriter.open(path) do |out|
            out.puts generate_translation_map
          end
        end
      end
    end
  end
end
