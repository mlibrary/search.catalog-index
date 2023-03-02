module Traject
  module UMich
    class PhysicalHolding
      attr_reader :holding_id

      def initialize(record:, holding_id:)
        @holding_id = holding_id
        @record = record
      end

      def summary_holdings
        output = []
        @record.each_by_tag("866") do |f|
          output.push(f['a']) if f["8"] == holding_id
        end
        output.join(" : ")
      end

      def items
        f974.map { |i| Traject::UMich::PhysicalItem.new(item: i, has_finding_aid: finding_aid?) }
      end

      def callnumber
        f852["h"]
      end

      def display_name
        ::UMich::LibLocInfo.display_name(library, location)
      end

      def floor_location
        return "" if callnumber.nil?
        ::UMich::FloorLocation.resolve(library, location, callnumber)
      end

      def info_link
        ::UMich::LibLocInfo.info_link(library, location)
      end

      def library
        f852["b"]
      end

      def location
        f852["c"]
      end

      def public_note
        f852["z"]
      end

      def field_is_finding_aid?(f)
        link_text = f["y"]
        link = f["u"]
        link_text =~ /finding aid/i and link =~ /umich/i
      end

      def finding_aid?
        @record.fields("856").any? { |f| field_is_finding_aid?(f) }
      end

      def f852
        @f852 ||= @record.fields("852").find { |f| f["8"] == @holding_id }
      end

      def f974
        @f974 ||= @record.fields("974").select { |f| f["8"] == @holding_id }
      end
    end
  end
end
