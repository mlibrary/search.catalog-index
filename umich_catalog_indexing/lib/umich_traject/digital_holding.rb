module Traject
  module UMich
    class DigitalHolding
      def initialize(avd)
        @avd = avd
      end
      def note
        @avd["z"]
      end
      def link
        URI::Parser.new.escape(@avd["u"].sub("01UMICH_INST:FLINT","01UMICH_INST:UMICH"))
      end
      def library
        "ELEC"
      end
      def status
        "Available"
      end
      def link_text
        "Available online"
      end
      def description
        ""
      end
      def finding_aid
        false
      end
      def to_h
        {
          finding_aid: finding_aid,
          library: library,
          link: link,
          link_text: link_text,
          note: note,
          status: status,
          description: description
        }
      end

    end
  end
end
