module Traject
  module UMich
    class DigitalHolding
      def initialize(avd)
        @avd = avd
      end
      # This concatenates the file type and the public note
      def public_note
        @avd["z"]
      end
      def link
        URI::Parser.new.escape(@avd["u"].sub("01UMICH_INST:FLINT","01UMICH_INST:UMICH"))
      end
      def library
        "ALMA_DIGITAL"
      end
      def link_text
        "Available online"
      end
      def label
        @avd["l"]
      end
      # This is effectively the file type(s)
      def delivery_description
        @avd["d"]
      end
      def finding_aid
        false
      end
      def to_h
        {
          library: library,
          link: link,
          link_text: link_text,
          delivery_description: delivery_description,
          label: label,
          public_note: public_note,
        }
      end

    end
  end
end
