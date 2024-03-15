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

      def oclc_nums
        acc = []
        oclcnum("035a:035z").call(@record, acc)
        acc
      end

      def has_oclc_num?(num)
        oclc_nums.include?(num)
      end
    end
  end
end
