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
          f974.map {|i| Traject::UMich::PhysicalItem.new(item: i, has_finding_aid: finding_aid?) }
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

        def finding_aid?
          record_has_finding_aid = false
          @record.each_by_tag("856") do |f|
             link_text = f["y"] 
             link = f["u"]
             if link_text =~ /finding aid/i and link =~ /umich/i
               record_has_finding_aid = true
               break
             end
          end
          record_has_finding_aid
        end

        def f852
          @f852 ||= begin 
            field = nil
            @record.each_by_tag("852") do |f|
              field = f if f["8"] == @holding_id 
            end
            field
          end
        end
        def f974
          @f974 ||= begin 
            output = []
            @record.each_by_tag("974") do |f|
              output.push(f) if f["8"] == @holding_id 
            end
            output
          end
        end
    end
  end
end
