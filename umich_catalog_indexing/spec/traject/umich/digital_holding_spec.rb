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
  context "#library" do
    it "shows ALMA_DIGITAL" do
      expect(subject.library).to eq("ALMA_DIGITAL")
    end
  end
  context "#link_text" do
    it "shows Available online" do
      expect(subject.link_text).to eq("Available online")
    end
  end
  context "#label" do
    it "shows the label from subfield l" do
      expect(subject.label).to eq("This is a label")
    end
  end
  context "#public_note" do
    it "shows the public note from subfield z" do
      expect(subject.public_note).to eq("This is a Public Note")
    end
  end
  context "#delivery_description" do
    it "show the delivery_description from subfield d" do
      expect(subject.delivery_description).to eq("2 file/s (Mixed)")
    end
  end
  context "#to_h" do
    it "returns expected hash" do
      expect(subject.to_h).to eq( 
        {
          library: "ALMA_DIGITAL",
          link: "https://umich-psb.alma.exlibrisgroup.com/discovery/delivery/01UMICH_INST:UMICH/121230624780006381",
          link_text: "Available online",
          delivery_description: "2 file/s (Mixed)",
          label: "This is a label",
          public_note: "This is a Public Note"
        }
      )
    end
  end
end

