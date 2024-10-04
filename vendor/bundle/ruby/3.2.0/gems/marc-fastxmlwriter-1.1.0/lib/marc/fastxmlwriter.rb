require "marc/fastxmlwriter/version"

require "marc"

module MARC
  class FastXMLWriter < MARC::XMLWriter
    XML_HEADER = '<?xml version="1.0" encoding="UTF-8"?>'

    OPEN_COLLECTION = "<collection>"
    OPEN_COLLECTION_NAMESPACE = %(<collection xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.loc.gov/MARC21/slim" xsi:schemaLocation="http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd">)

    def initialize(file, opts = {})
      super
    end

    def write(record)
      @fh.write(self.class.encode(record))
      # @fh.write("\n")
    end

    class << self
      def open_collection(use_ns)
        if use_ns
          OPEN_COLLECTION_NAMESPACE.dup
        else
          OPEN_COLLECTION.dup
        end
      end

      def single_record_document(r, include_namespace: true)
        xml = XML_HEADER.dup
        xml << open_collection(include_namespace)
        xml << encode(r)
        xml << "</collection>"
        xml
      end

      def open_datafield(tag, ind1, ind2)
        "<datafield tag=\"#{tag}\" ind1=\"#{ind1}\" ind2=\"#{ind2}\">"
      end

      def open_subfield(code)
        # return "\n    <subfield code=\"#{code}\">"
        "<subfield code=\"#{code}\">"
      end

      def open_controlfield(tag)
        # return "\n<controlfield tag=\"#{tag}\">"
        "<controlfield tag=\"#{tag}\">"
      end

      def encode(r)
        xml = "<record>"

        # MARCXML only allows alphanumerics or spaces in the leader
        lead = r.leader.gsub(/[^\w|^\s]/, "Z").encode(xml: :text)

        # MARCXML is particular about last four characters; ILSes aren't
        lead.ljust(23, " ")[20..23] = "4500"

        # MARCXML doesn't like a space here so we need a filler character: Z
        if lead[6..6] == " "
          lead[6..6] = "Z"
        end

        xml << "<leader>" << lead.encode(xml: :text) << "</leader>"
        r.each do |f|
          if f.instance_of?(MARC::DataField)
            xml << open_datafield(f.tag, f.indicator1, f.indicator2)
            f.each do |sf|
              xml << open_subfield(sf.code) << sf.value.encode(xml: :text) << "</subfield>"
            end
            xml << "</datafield>"
          elsif f.instance_of?(MARC::ControlField)
            xml << open_controlfield(f.tag) << f.value.encode(xml: :text) << "</controlfield>"
          end
        end
        xml << "</record>"
        xml.force_encoding("utf-8")
      end
    end
  end
end
