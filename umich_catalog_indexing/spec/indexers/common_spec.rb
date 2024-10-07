describe "indexers common" do
  let(:indexer) do
    Traject::Indexer.new do
      load_config_file("./spec/support/traject_settings.rb")
      load_config_file("./indexers/common.rb")
    end
  end
  before(:each) do
    @record = get_record("spec/fixtures/grudencz.xml")
  end
  subject do
    indexer.process_record(@record).output_hash
  end
  context "language" do
    it "gets language from 008 and 041" do
      expect(subject["language"]).to contain_exactly("Latin", "Czech")
    end
    it "ignores languages that have a subfield 2 in 041" do
      @record["041"].append(MARC::Subfield.new("2", "some_value"))
      expect(subject["language"]).to contain_exactly("Latin")
    end
  end
end
