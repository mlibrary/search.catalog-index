module Jobs
  module TranslationMapGenerator
    module ElectronicCollections
      class << self
        include FileWriter
        # @returns [String] name of the translation map
        def name
          "Electronic Collections"
        end

        # @returns [String] where in the translation map directory the file
        # should go
        def file_path
          File.join("umich", "electronic_collections.yaml")
        end

        # @returns [String] YAML string of translation map
        def generate
          fetch.to_yaml(line_width: 1000)
        end

        def fetch
          response = AlmaRestClient.client.get_report(path: "/shared/University of Michigan 01UMICH_INST/Reports/apps/library-search/electronic-collections")
          List.new(response.body).to_h
        end

        # This is used for debugging.
        def all
          response = AlmaRestClient.client.get_report(path: "/shared/University of Michigan 01UMICH_INST/Reports/apps/library-search/electronic-collections")
          List.new(response.body)
        end
      end

      class List
        def initialize(data)
          @data = data
        end

        def items
          @data.map { |x| Item.for(x) }
        end

        def to_h
          # create a Hash where values are unique empty arrays
          output = Hash.new { |h, k| h[k] = [] }
          items.each { |x| output[x.mms_id].push(x.to_h) }

          # Sometimes there are collections that would have duplicate collection
          # link info. This only grabs the unique collection info for Library
          # Search.
          output.each do |k, v|
            output[k] = v.uniq
          end
          output
        end
      end

      class Item
        CAMPUS_TO_INST_CODE = {
          "ann_arbor" => "MIU",
          "flint" => "MIFLIC"
        }
        def self.for(data)
          if data["Electronic Collection Level URL (override)"] || data["Electronic Collection Level URL"]
            AvailableItem.new(data)
          else
            UnavailableItem.new(data)
          end
        end

        # The ElectronicCollections::Item object calculates the appropriate values
        # for an Electronic Collection record to fill out an Electronic Holding
        # entry in the :hol field in the solr document
        # @param data [Hash] a row from the electronic-collections analytics
        # report
        def initialize(data)
          @data = data
        end

        def mms_id
          @data["E-Collection Bib - MMS Id"]
        end

        # Collection ID. This isn't included in the hash because we want to be
        # able to collapse otherwise identical information, and we don't actually
        # do anything with the Collection ID.
        def collection_id
          @data["Electronic Collection Id"]
        end

        def campuses
          @data["Available For Group"]
            &.split("; ")
            &.map { |x| x.downcase.strip.sub("\s", "_") } || CAMPUS_TO_INST_CODE.keys
        end

        def institution_codes
          if campuses.nil?
            CAMPUS_TO_INST_CODE.values
          else
            campuses.map { |x| CAMPUS_TO_INST_CODE[x] }
          end
        end

        def link
          parser = URI::DEFAULT_PARSER
          parser.escape(preferred_value("Electronic Collection Level URL") || "")
        end

        def collection_name
          preferred_value("Electronic Collection Public Name")
        end

        def interface_name
          i_name = preferred_value("Electronic Collection Interface Name")
          (i_name == "None") ? "" : i_name
        end

        # Concatentates interface name, public note, and authentication note.
        # Also strips out any trailing punctuation except closing parens and
        # square brackets. The rest are terminated with a period.
        def note
          [
            interface_name,
            @data["Electronic Collection Public Note"],
            @data["Electronic Collection Authentication Note"]
          ].compact.map do |x|
            out = x.strip
              .sub(/[[\p{P}]&&[^\])]]$/, "")
            out.sub!(/$/, ".") if out.match?(/[^\])]$/)
            out
          end.join(" ").strip
        end

        # Returns a hash summary of the collection metadata. This becomes a row in
        # the map
        def to_h
          [
            "collection_name",
            "interface_name",
            "note",
            "link",
            "status",
            "campuses",
            "institution_codes"
          ].map do |x|
            [x, send(x)]
          end.to_h
        end

        private

        def preferred_value(key)
          @data["#{key} (override)"] || @data[key]
        end
      end

      class UnavailableItem < Item
        def status
          "Not Available"
        end
      end

      class AvailableItem < Item
        def status
          "Available"
        end
      end
    end
  end
end
