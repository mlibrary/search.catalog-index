require "traject"
describe "callnumber_browse" do
  let(:hurdy_gurdy) do
    get_record("./spec/fixtures/hurdy_gurdy.xml")
  end
  let(:indexer) do
    Traject::Indexer.new do
      load_config_file("./spec/support/traject_settings.rb")
      load_config_file("./indexers/common.rb")
      load_config_file("./indexers/callnumbers.rb")
    end
  end
  before(:each) do
    @record = nil
  end
  subject do
    indexer.process_record(@record).output_hash
  end
  it "adds a callnumber to callnumber_browse field" do
    @record = hurdy_gurdy
    expect(subject["callnumber_browse"]).to eq(["ML760 .P18"])
  end
  it "does not include single and double letter callnumbers" do
    # N and ZZ are invalid callnumbers. They break call number browse.
    @record = hurdy_gurdy
    @record.append(MARC::DataField.new("852", "0", "0",
      ["h", "ZZ"]))
    @record.append(MARC::DataField.new("852", "0", "0",
      ["h", "N"]))
    @record.append(MARC::DataField.new("852", "0", "0",
      ["h", "ML760 .P18 2025"]))
    expect(subject["callnumber_browse"]).to eq(["ML760 .P18", "ML760 .P18 2025"])
  end
end
