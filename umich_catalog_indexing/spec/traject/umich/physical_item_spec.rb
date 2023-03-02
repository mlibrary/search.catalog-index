require "traject"
require "umich_traject"
describe Traject::UMich::PhysicalItem do
  def get_record(path)
    reader = MARC::XMLReader.new(path)
    for r in reader
      return r
    end
  end
  let(:arborist) do
    get_record('./spec/fixtures/arborist.xml')
  end
  before(:each) do
    @item = arborist["974"]
    @has_finding_aid = false
  end
  subject do
    described_class.new(item: @item, has_finding_aid: @has_finding_aid)
  end
  context "#barcode" do
    it "has an appropriate barcode" do
      expect(subject.barcode).to eq("A113546")
    end
  end
  context "#callnumber" do
    it "has an appropriate callnumber" do
      expect(subject.callnumber).to eq("SB 435 .A71")
    end
  end
  context "#can_reserve?" do
    it "is true when a BENT|CLEM|SPEC and does not have finding aid" do
      @item.subfields.each do |s|
        if s.code == "b"
          s.value = "SPEC"
        end
      end
      expect(subject.can_reserve?).to eq(true)
    end
    it "is false when BENT|CLEM|SPEC and does have finding aid" do
      @has_finding_aid = true
      @item.subfields.each do |s|
        if s.code == "b"
          s.value = "SPEC"
        end
      end
      expect(subject.can_reserve?).to eq(false)
    end
    it "is false when NOT BENT|CLEM|SPEC" do
      expect(subject.can_reserve?).to eq(false)
    end
  end
  context "#description" do
    it "has an appropriate description" do
      expect(subject.description).to eq("v.31:no.2(2022:Apr.)")
    end
  end
  context "#display_name" do
    it "has an appropriate display_name" do
      expect(subject.display_name).to eq("Shapiro Science Oversize Stacks - 4th floor")
    end
  end
  context "#fulfillment_unit" do
    it "has an appropriate fulfillment_unit" do
      expect(subject.fulfillment_unit).to eq("General")
    end
  end
  context "#info_link" do
    it "has an appropriate info_link" do
      expect(subject.info_link).to eq("http://lib.umich.edu/locations-and-hours/shapiro-library")
    end
  end
  context "#inventory_number" do
    it "has an appropriate inventory_number" do
      expect(subject.inventory_number).to eq(nil)
    end
  end
  context "#item_id" do
    it "has an appropriate item_id" do
      expect(subject.item_id).to eq("231228590060006381")
    end
  end
  context "#item_policy" do
    it "has an appropriate item_policy" do
      expect(subject.item_policy).to eq("08")
    end
  end
  context "#library" do
    it "has an appropriate library" do
      expect(subject.library).to eq("SHAP")
    end
  end
  context "#location" do
    it "has an appropriate location" do
      expect(subject.location).to eq("SOVR")
    end
  end
  context "#permanent_library" do
    it "has an appropriate permanent_library" do
      expect(subject.permanent_library).to eq("SHAP")
    end
  end
  context "#permanent_location" do
    it "has an appropriate permanent_location" do
      expect(subject.permanent_location).to eq("SOVR")
    end
  end
  context "#process_type" do
    it "has an appropriate process_type" do
      expect(subject.process_type).to eq(nil)
    end
  end
  context "#public_note" do
    it "has an appropriate public_note" do
      expect(subject.public_note).to eq(nil)
    end
  end
  context "#finding_aid?" do
    it "has an appropriate finding_aid?" do
      expect(subject.finding_aid?).to eq(false)
    end
  end
  context "#temp_location?" do
    it "has an appropriate temp_location" do
      expect(subject.temp_location?).to eq(false)
    end
  end
  context "#locations" do
    it "returns an array of library and library plus location" do
      expect(subject.locations).to eq(["SHAP", "SHAP SOVR"])
    end
    it "returns only the library if there is no location" do
      @item.subfields.each do |s|
        if s.code == "c"
          s.value = nil 
        end
      end
      expect(subject.locations).to eq(["SHAP"])
    end
  end
  context "#circulating?" do
    it "is true when field 'f' is '1'" do
      expect(subject.circulating?).to eq(true)
    end
  end
end

