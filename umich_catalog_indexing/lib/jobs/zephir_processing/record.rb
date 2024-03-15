require "traject/macros/marc21_semantics"
module Jobs
  module ZephirProcessing
    class Record
      attr_reader :raw
      include Traject::Macros::Marc21Semantics
      def initialize(raw)
        @raw = raw
        @record = MARC::JSONLReader.new(StringIO.new(@raw)).first
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
