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
        Traject::UMich::EnumcronSorter.sort( 
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
          callnumber: callnumber,
          display_name: display_name,
          floor_location: floor_location,
          hol_mmsid: holding_id,
          info_link: info_link,
          items: items.map{|x| x.to_h},
          library: library,
          location: location,
          public_note: public_note,
          record_has_finding_aid: finding_aid?,
          summary_holdings: summary_holdings
        }
      end

      def enumcronSort a, b
        return a[:sortstring] <=> b[:sortstring]
      end

      def enumcronSortString str
        rv = '0'
        str.scan(/\d+/).each do |nums|
          rv += nums.size.to_s + nums
        end
        return rv
      end

      def sortItems(arr)
        # Only one? Never mind
        return arr if arr.size == 1
      
        # First, add the _sortstring entries
        arr.each do |h|
          #if h.has_key? 'description'
          if h[:description]
            h[:sortstring] = enumcronSortString(h[:description])
          else
            h[:sortstring] = '0'
          end
        end
      
        # Then sort it
        arr.sort! { |a, b| self.enumcronSort(a, b) }
      
        # Then remove the sortstrings
        arr.each do |h|
          h.delete(:sortstring)
        end
        return arr
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
