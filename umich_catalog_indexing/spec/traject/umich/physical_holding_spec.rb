require "traject"
require "umich_traject"
describe Traject::UMich::PhysicalHolding do
  def get_record(path)
    reader = MARC::XMLReader.new(path)
    for r in reader
      return r
    end
  end
  let(:arborist) do
    get_record('./spec/fixtures/arborist.xml')
  end
  let(:holding_id) { "22767949280006381" }
  before(:each) do
    @record = arborist
  end
  subject do
    described_class.new(record: @record, holding_id: holding_id) 
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
      @record["852"].subfields.each do |s|
        case s.code
        when "b"
          s.value = "HATCH"
        when "c"
          s.value = "GRAD"
        when "h"
          s.value = nil 
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
  context "public_note" do
    it "returns the appropriate public_note" do
      expect(subject.public_note).to eq("CURRENT ISSUES IN SERIAL SERVICES, 203 NORTH HATCHER")
    end
  end
  context "items" do
    it "returns an array of items" do
      expect(subject.items.count).to eq(2)
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
      @record["856"].append(MARC::Subfield.new("y","Finding aid"))
      expect(subject.finding_aid?).to eq(true)
    end
    it "returns false if there isn't a Finding aid" do
      expect(subject.finding_aid?).to eq(false)
    end
  end

end
