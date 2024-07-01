require "traject"
require "umich_traject"
describe Traject::UMich::Availability do
  before(:each) do
    @hol = JSON.parse(fixture("/hol.json"))
  end
  subject do
    described_class.new(@hol)
  end
  context "#physical?" do
    it "is true when there is at least one physical item" do
      expect(subject.physical?).to eq(true)
    end
    it "is false when there are no physical items" do
      @hol.delete_at(0)
      expect(subject.physical?).to eq(false)
    end
  end
  context "#hathi_trust?" do
    it "is true when there is at least one HathiTrust item" do
      expect(subject.hathi_trust?).to eq(true)
    end
    it "is false when there are no HathiTrust items" do
      @hol.delete_at(1)
      expect(subject.hathi_trust?).to eq(false)
    end
  end
  context "#hathi_trust_full_text?" do
    it "is true when there is at least one HathiTrust item that is full text" do
      @hol[1]["items"].push({"rights" => "pd"})
      expect(subject.hathi_trust_full_text?).to eq(true)
    end
    it "is false when there are no public domain items" do
      expect(subject.hathi_trust_full_text?).to eq(false)
    end
    it "is false when there are no HathiTrust items" do
      @hol.delete_at(1)
      expect(subject.hathi_trust_full_text?).to eq(false)
    end
  end

  context "#electronic_holding?" do
    it "is true when there is an alma electronic record" do
      @hol[1]["library"] = "ELEC"
      expect(subject.electronic_holding?).to eq(true)
    end
    it "is true when there is an alma digital record" do
      @hol[1]["library"] = "ALMA_DIGITAL"
      expect(subject.electronic_holding?).to eq(true)
    end
    it "is false when there is only HathiTrust" do
      expect(subject.electronic_holding?).to eq(false)
    end
  end

  context "hathi_trust_or_electronic_holding?" do
    it "returns true when hathitrust item" do
      expect(subject.hathi_trust_or_electronic_holding?).to eq(true)
    end
    it "returns true when there's an electronic holding" do
      @hol[1]["library"] = "ELEC"
      expect(subject.hathi_trust_or_electronic_holding?).to eq(true)
    end
    it "returns false when there's no electronic or HT record" do
      @hol.delete_at(1)
      expect(subject.hathi_trust_or_electronic_holding?).to eq(false)
    end
  end

  context "hathi_trust_full_text_or_electronic_holding?" do
    it "returns false when neither ht full text or electronic holding" do
      expect(subject.hathi_trust_full_text_or_electronic_holding?).to eq(false)
    end
    it "returns true when hathitrust full text" do
      @hol[1]["items"].push({"rights" => "pd"})
      expect(subject.hathi_trust_full_text_or_electronic_holding?).to eq(true)
    end
    it "returns true when there's an electronic holding" do
      @hol[1]["library"] = "ELEC"
      expect(subject.hathi_trust_full_text_or_electronic_holding?).to eq(true)
    end
  end

  context "#to_a" do
    it "returns an array of availability values" do
      expect(subject.to_a).to contain_exactly(
        "physical", "hathi_trust", "hathi_trust_or_electronic_holding"
      )
    end
  end
end
