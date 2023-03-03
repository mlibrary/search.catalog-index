module Traject
  module UMich
    class PhysicalItem
      def initialize(item:, has_finding_aid:)
        @item = item
        @has_finding_aid = has_finding_aid
      end
      def barcode
        @item["a"]
      end
      def should_be_suppressed
        /Process Status: (CA|WN|WD)/.match?(@item["y"]) ||
        ["ELEC","SDR"].include?(library)
      end
      def callnumber
        @item["h"]
      end
      def can_reserve?
        ["BENT","CLEM","SPEC"].include?(library) && !finding_aid?
      end
      def description
        @item["z"]
      end
      def display_name
        ::UMich::LibLocInfo.display_name(library, location) 
      end
      def fulfillment_unit
        ::UMich::LibLocInfo.fulfillment_unit(library, location) 
      end
      def info_link
        ::UMich::LibLocInfo.info_link(library, location) 
      end
      def inventory_number
        @item["i"]
      end
      def item_id
        @item["7"]
      end
      def item_policy
        @item["p"]
      end
      def library
        @item["b"]
      end
      def location
        @item["c"]
      end
      def locations
        [library, "#{library} #{location}".strip].uniq
      end
      def permanent_library
        @item["d"]
      end
      def permanent_location
        @item["e"]
      end
      def process_type
        @item["t"]
      end
      def public_note
        @item["n"]
      end
      def finding_aid?
        @has_finding_aid
      end
      def temp_location?
        library != permanent_library || location != permanent_location
      end
      def circulating?
        @item["f"] == "1"
      end
      def to_h
        {
          barcode: barcode,
          callnumber: callnumber,
          can_reserve: can_reserve?,
          description: description,
          display_name: display_name,
          fulfillment_unit: fulfillment_unit,
          info_link: info_link,
          inventory_number: inventory_number,
          item_id: item_id,
          item_policy: item_policy,
          library: library,
          location: location,
          permanent_library: permanent_library,
          permanent_location: permanent_location,
          process_type: process_type,
          public_note: public_note,
          record_has_finding_aid: finding_aid?,
          temp_location: temp_location?
        }
      end
    end
  end
end
