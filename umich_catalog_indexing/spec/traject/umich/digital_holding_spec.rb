require "traject"
require "umich_traject"
describe Traject::UMich::DigitalHolding do
  def get_record(path)
    reader = MARC::XMLReader.new(path)
    for r in reader
      return r
    end
  end
  let(:arborist) do
    get_record('./spec/fixtures/arborist_avd.xml')
  end
  let(:avd) do
    arborist.fields("AVD").first
  end
  subject do
    described_class.new(avd)
  end
  context "#link" do
    it "returns the link with the UMICH view" do
      expect(subject.link).to eq("https://umich-psb.alma.exlibrisgroup.com/discovery/delivery/01UMICH_INST:UMICH/121230624780006381")
    end
  end
  context "#note" do
    it "returns the z field" do
      expect(subject.note).to eq("This is a Public Note")
    end
  end
  context "#library" do
    it "shows ELEC" do
      expect(subject.library).to eq("ELEC")
    end
  end
  context "#status" do
    it "shows Available" do
      expect(subject.status).to eq("Available")
    end
  end
  context "#link_text" do
    it "shows Available online" do
      expect(subject.link_text).to eq("Available online")
    end
  end
  context "#description" do
    it "shows empty string" do
      expect(subject.description).to eq("")
    end
  end
  context "#finding_aid" do
    it "is false" do
      expect(subject.finding_aid).to eq(false)
    end
  end
  context "#to_h" do
    it "returns expected hash" do
      expect(subject.to_h).to eq( 
        {
          finding_aid: false,
          library: "ELEC",
          link: "https://umich-psb.alma.exlibrisgroup.com/discovery/delivery/01UMICH_INST:UMICH/121230624780006381",
          link_text: "Available online",
          note: "This is a Public Note",
          status: "Available",
          description: ""
        }
      )
    end
  end
end

