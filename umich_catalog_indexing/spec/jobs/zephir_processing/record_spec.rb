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
      expect(subject.oclc_nums).to eq([21963194])
    end
  end
  context "#has_oclc_num?" do
    it "returns true if there's a match" do
      expect(subject.has_oclc_num?(21963194)).to eq(true)
    end
    it "returns false when there isn't a match" do
      expect(subject.has_oclc_num?(1111)).to eq(false)
    end
  end
  context "#no_full_text?" do
    it "returns true when there are no Full Text items associated with the record" do
      expect(subject.no_full_text?).to eq(true)
    end
    it "returns false when there is at least one Full Text item associated with the record" do
      @zephir_record["fields"][45]["974"]["subfields"][7]["r"] = "pdus"
      expect(subject.no_full_text?).to eq(false)
    end
    it "returns true when record includes pd-pvt items" do
      @zephir_record["fields"][45]["974"]["subfields"][7]["r"] = "pd-pvt"
      expect(subject.no_full_text?).to eq(true)
    end
  end
  context "#is_umich?" do
    it "returns true when umich is the preffered record" do
      @zephir_record["fields"][42]["HOL"]["subfields"][3]["c"] = "MIU"
      expect(subject.is_umich?).to eq(true)
    end
    it "returns true when umich is the record source" do
      @zephir_record["fields"][8]["035"]["subfields"][0]["a"].sub!("sdr-ucsd", "sdr-miu")
      expect(subject.is_umich?).to eq(true)
    end
    it "returns false when umich is not the record source" do
      expect(subject.is_umich?).to eq(false)
    end
  end
end
