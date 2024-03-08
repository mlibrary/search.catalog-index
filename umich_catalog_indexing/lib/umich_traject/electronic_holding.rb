module Traject
  module UMich
    class ElectronicHolding
      def initialize(e56)
        @e56 = e56
      end

      def library
        "ELEC"
      end

      def link
        code_map = {
          "ann_arbor" => "UMAA",
          "flint" => "UMFL"
        }
        URI::DEFAULT_PARSER.escape(@e56["u"].sub("openurl", "openurl-#{code_map[link_campus]}"))
      end

      def link_text
        "Available online"
      end

      def link_campus
        # return flint when it's the only campus
        if _alma_campuses.count == 1 && _alma_campuses.first == "UMFL"
          "flint"
        else
          "ann_arbor"
        end
      end

      def institution_codes
        inst_code_map = {
          "UMAA" => "MIU",
          "UMFL" => "MIFLIC"
        }
        if _alma_campuses.empty?
          inst_code_map.values
        else
          _alma_campuses.map { |code| inst_code_map[code] }
        end
      end

      def interface_name
        @e56["m"]
      end

      def collection_name
        @e56["n"]
      end

      def authentication_note
        @e56.subfields.filter_map { |x| x.value if x.code == "4" }
      end

      def public_note
        @e56["z"]
      end

      def note
        [
          interface_name,
          collection_name,
          authentication_note,
          public_note
        ].flatten.map do |x|
          x.strip.sub(/\p{P}$/, "").sub(/$/, ".")
        end.join(" ")
      end

      def status
        @e56["s"]
      end

      def description
        @e56["3"]
      end

      def finding_aid
        false
      end

      def to_h
        {
          library: library,
          link: link,
          link_text: link_text,
          institution_codes: institution_codes,
          interface_name: interface_name,
          collection_name: collection_name,
          authentication_note: authentication_note,
          public_note: public_note,
          note: note,
          finding_aid: finding_aid
        }
      end

      def _alma_campuses
        @e56.subfields.filter_map { |x| x.value if x.code == "c" }
      end
    end
  end
end
