require "minitest_helper"
require "marc"
require "stringio"
require "nokogiri"

describe "loads" do
  it "loads the constant" do
    assert defined? MARC::FastXMLWriter
  end
end

ROUND_TRIP_FILES = Dir.glob(test_data_dir + "/*")

describe "round-trip tests" do
  describe "Using namespace" do
    describe "rexml" do
      ROUND_TRIP_FILES.each do |filename|
        MARC::Reader.new(filename).each_with_index do |r1, i|
          it "round-trips to/from xml and MARC::Record with namespace" do
            use_namespace = true
            xml = MARC::FastXMLWriter.single_record_document(r1, include_namespace: use_namespace)
            srexml = StringIO.new(xml.dup)
            r3 = MARC::XMLReader.new(srexml, parser: "rexml", ignore_namespace: !use_namespace).first
            assert_equal r1, r3, "File #{filename} record #{i}, rexml with include_namespace = #{use_namespace}"
          end
        end
      end
    end
  end

  describe "nokogiri" do
    ROUND_TRIP_FILES.each do |filename|
      MARC::Reader.new(filename).each_with_index do |r1, i|
        it "round-trips to/from xml and MARC::Record with namespace" do
          use_namespace = true
          xml = MARC::FastXMLWriter.single_record_document(r1, include_namespace: use_namespace)
          srexml = StringIO.new(xml.dup)
          r3 = MARC::XMLReader.new(srexml, parser: "nokogiri", ignore_namespace: !use_namespace).first
          assert_equal r1, r3, "File #{filename} record #{i}, nokogiri with include_namespace = #{use_namespace}"
        end
      end
    end
  end
end
