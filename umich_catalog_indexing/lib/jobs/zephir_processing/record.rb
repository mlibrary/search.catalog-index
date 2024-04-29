require "traject/macros/marc21_semantics"
require "ht_traject/ht_macros"
module Jobs
  module ZephirProcessing
    class Record
      attr_reader :raw
      include Traject::Macros::Marc21Semantics
      include HathiTrust::Traject::Macros
      def initialize(raw)
        @raw = raw
        @record = MARC::Record.new_from_hash(JSON.parse(@raw))
      end

      # Does the record only contain in copyright materials? Restated:
      # Does the record not have any public domain materials?
      # return [Boolean]
      def no_full_text?
        has_at_least_one_full_text = @record.fields("974")
          .map { |x| x["r"] } # get the rights subfield
          .any? do |rights| # do any of the rights options match full text?
            statusFromRights(rights) == "Full text"
          end
        !has_at_least_one_full_text
      end

      def is_umich?
        # umich record is preferred record
        return true if @record["HOL"]["c"] == "MIU"

        oh35a_spec = Traject::MarcExtractor.cached("035a")
        (oh35a_spec.extract(@record).any? do |oh35a|
          oh35a.match?(/^sdr-miu/i)
        end) ? true : false
      end

      def oclc_nums
        acc = []
        oclcnum("035a:035z").call(@record, acc)
        acc.map { |x| x.to_i }
      end

      def has_oclc_num?(num)
        oclc_nums.include?(num)
      end
    end
  end
end
