module Traject
  module UMich
    class PhysicalHolding
      attr_reader :holding_id

      def initialize(record:, holding_id:)
        @holding_id = holding_id
        @record = record
      end

      def institution_code
        f852["a"].upcase
      end

      def summary_holdings
        output = []
        @record.each_by_tag("866") do |f|
          output.push(f['a']) if f["8"] == holding_id
        end
        str = output.join(" : ")
        str == "" ? nil : str
      end

      def items
        @items ||= Traject::UMich::EnumcronSorter.sort( 
          f974.map do |i| 
            Traject::UMich::PhysicalItem.new(item: i, has_finding_aid: finding_aid?) 
          end.reject do |x|
            x.should_be_suppressed
          end
        )
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

      def locations
        [library, "#{library} #{location}".strip].push( items.map{|x| x.locations } ).flatten.uniq
      end
      def circulating?
        items.any?{ |x| x.circulating? }
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
      def to_h 
        {
          hol_mmsid: holding_id,
          callnumber: callnumber,
          library: library,
          location: location,
          info_link: info_link,
          display_name: display_name,
          floor_location: floor_location,
          public_note: public_note,
          items: items.map{|x| x.to_h},
          summary_holdings: summary_holdings,
          record_has_finding_aid: finding_aid?,
        }
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
