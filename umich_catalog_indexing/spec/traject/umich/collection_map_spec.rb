describe Traject::UMich do
  context ".collection" do
    it "returns the collection string when there is one" do
      expect(described_class.collection_map("AAEL MAIN")).to eq("Main Collection")
      expect(described_class.collection_map("SPEC THC")).to eq("Transportation History Collection")
    end
    it "returns nil when there isn't a match" do
      expect(described_class.collection_map("NOT REAL")).to be_nil
    end
    it "returns nil for string without a space" do
      expect(described_class.collection_map("NOTREAL")).to be_nil
    end
  end
end
