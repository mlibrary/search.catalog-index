require "traject"
require "umich_traject"
describe Traject::UMich::PhysicalHolding do
  let(:arborist) do
    get_record("./spec/fixtures/arborist.xml")
  end
  let(:holding_id) { "22767949280006381" }
  before(:each) do
    @record = arborist
  end
  subject do
    described_class.new(record: @record, holding_id: holding_id)
  end
  context "#institution_code" do
    it "returns upcased institution code" do
      expect(subject.institution_code).to eq("MIU")
    end
  end
  context "#holding_id" do
    it "returns the holding_id" do
      expect(subject.holding_id).to eq(holding_id)
    end
  end
  context "#summary_holdings" do
    it "returns the appropriate summary holdings" do
      expect(subject.summary_holdings).to eq("2- : 1993-")
    end
  end
  context "#callnumber" do
    it "returns the appropriate callnumber" do
      expect(subject.callnumber).to eq("SB 435 .A71")
    end
  end
  context "#display_name" do
    it "returns the appropriate display name" do
      expect(subject.display_name).to eq("Shapiro Science Oversize Stacks - 4th floor")
    end
  end
  context "floor_location" do
    it "returns the appropriate floor location" do
      @record["852"].subfields.each do |s|
        case s.code
        when "b"
          s.value = "HATCH"
        when "c"
          s.value = "GRAD"
        when "h"
          s.value = "822.8 A676wp 1967"
        end
      end
      expect(subject.floor_location).to eq("3 South")
    end
    it "handles nil callnumber" do
      @record.fields("852").each do |f|
        f.subfields.each do |s|
          case s.code
          when "b"
            s.value = "HATCH"
          when "c"
            s.value = "GRAD"
          when "h"
            s.value = nil
          end
        end
      end
      expect(subject.floor_location).to eq("")
    end
  end
  context "info_link" do
    it "returns the appropriate info link" do
      expect(subject.info_link).to eq("http://lib.umich.edu/locations-and-hours/shapiro-library")
    end
  end
  context "library" do
    it "returns the appropriate library" do
      expect(subject.library).to eq("SHAP")
    end
  end
  context "location" do
    it "returns the appropriate location" do
      expect(subject.location).to eq("SOVR")
    end
  end
  context "#circulating?" do
    it "is true if any of the 974s have f=1" do
      expect(subject.circulating?).to eq(true)
    end
    it "is false if none of the 974s have f = 1" do
      @record.fields("974").each do |f|
        f.subfields.each do |s|
          s.value = "0" if s.code == "f"
        end
      end
      expect(subject.circulating?).to eq(false)
    end
  end
  context "#locations" do
    it "returns an array of library and library plus location" do
      expect(subject.locations).to eq(["SHAP", "SHAP SOVR"])
    end
    it "returns only the library if there is no location in the holding or item record" do
      @record["974"].subfields.each do |s|
        s.value = "LOCATION" if s.code == "c"
        s.value = "LIBRARY" if s.code == "b"
      end
      expect(subject.locations).to eq(["SHAP", "SHAP SOVR", "LIBRARY", "LIBRARY LOCATION"])
    end
    it "returns only the library if there is no location in the holding or item record" do
      @record.fields("852").each do |f|
        f.subfields.each do |s|
          if s.code == "c"
            s.value = nil
          end
        end
      end

      @record.fields("974").each do |f|
        f.subfields.each do |s|
          if s.code == "c"
            s.value = nil
          end
        end
      end
      expect(subject.locations).to eq(["SHAP"])
    end
  end
  context "public_note" do
    it "returns the appropriate public_note" do
      expect(subject.public_note).to eq("CURRENT ISSUES IN SERIAL SERVICES, 203 NORTH HATCHER")
    end
  end
  context "items" do
    it "returns an array of items" do
      expect(subject.items.count).to eq(2)
    end
    it "doesn't include process type CA" do
      @record["974"].append(MARC::Subfield.new("y", "Process Status: CA"))
      expect(subject.items.count).to eq(1)
    end
  end
  context "finding_aid?" do
    it "returns the appropriate finding_aid?" do
      @record["856"].subfields.each do |s|
        case s.code
        when "u"
          s.value = "http://quod.lib.umich.edu/c/clementsead/umich-wcl-M-2015mit?view=text"
        end
      end
      @record["856"].append(MARC::Subfield.new("y", "Finding aid"))
      expect(subject.finding_aid?).to eq(true)
    end
    it "returns false if there isn't a Finding aid" do
      expect(subject.finding_aid?).to eq(false)
    end
  end
  context "to_h" do
    it "returns a hash with the expected keys" do
      keys = [:callnumber, :display_name, :floor_location, :hol_mmsid,
        :info_link, :items, :library, :location, :public_note,
        :record_has_finding_aid, :summary_holdings]
      expect(subject.to_h.keys.sort).to eq(keys)
    end
  end
end
