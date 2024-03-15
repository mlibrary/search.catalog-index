describe Jobs::ZephirProcessing::Record do
  before(:each) do
    @zephir_record = JSON.parse(fixture("zephir_record.json"))
  end
  subject do
    described_class.new(@zephir_record.to_json)
  end
  context "#raw" do
    it "returns the raw json string" do
      expect(subject.raw).to eq(@zephir_record.to_json)
    end
  end
  context "#oclc_nums" do
    it "returns the oclc_nums in the record" do
      expect(subject.oclc_nums).to eq(["21963194"])
    end
  end
  context "#has_oclc_num?" do
    it "returns true if there's a match" do
      expect(subject.has_oclc_num?("21963194")).to eq(true)
    end
    it "returns false when there isn't a match" do
      expect(subject.has_oclc_num?("1111")).to eq(false)
    end
  end
end
