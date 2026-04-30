require "traject"
describe "callnumbers" do
  let(:hurdy_gurdy) do
    get_record("./spec/fixtures/hurdy_gurdy.xml")
  end
  before(:all) do
    @indexer = Traject::Indexer.new do
      load_config_file("./spec/support/traject_settings.rb")
      load_config_file("./indexers/common.rb")
      load_config_file("./indexers/callnumbers.rb")
    end
  end
  before(:each) do
    @record = nil
  end
  subject do
    @indexer.process_record(@record).output_hash
  end
  context "callnumber_browse" do
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
    it "does not include any callnumbers when the item type is j" do
      @record = hurdy_gurdy
      @record.leader[6] = "j"
      expect(subject["callnumber_browse"]).to be_nil
    end
    it "does not include any callnumbers when the item type g" do
      @record = hurdy_gurdy
      @record.leader[6] = "g"
      expect(subject["callnumber_browse"]).to be_nil
    end
    it "does not include call numbers with W or w" do
      @record = hurdy_gurdy
      @record.fields.delete_if { |x| x.tag == "852" }
      @record.append(MARC::DataField.new("050", "", "4",
        ["a", "WB 925"], ["b", ".H236 2006"]))
      @record.append(MARC::DataField.new("050", "", "4",
        ["a", "wb 925"], ["b", ".H236 2006"]))
      expect(subject["callnumber_browse"]).to be_nil
    end
  end
  context "hlb3Delimited" do
    let(:reading_grade) { MARC::DataField.new("521", "0", "", ["a", "12.8"]) }
    let(:interest_age) { MARC::DataField.new("521", "1", "", ["a", "008-012"]) }
    let(:interest_grade) { MARC::DataField.new("521", "2", "", ["a", "12 & up"]) }
    it "does not include children's literature when there's no need to" do
      @record = hurdy_gurdy
      expect(subject["hlb3Delimited"]).not_to include("Humanities | Children's Literature")
    end
    it "includes children's literature when 008 has 22 a" do
      # a, b, c, d, or j
      @record = hurdy_gurdy
      @record["008"].value[22] = "a"
      expect(subject["hlb3Delimited"]).to include("Humanities | Children's Literature")
    end
    it "includes reading grade <= 12" do
      @record = hurdy_gurdy
      @record.append(reading_grade)
      expect(subject["hlb3Delimited"]).to include("Humanities | Children's Literature")
    end
    it "does not include reading grade > 12" do
      @record = hurdy_gurdy
      @record.append(reading_grade)
      @record["521"].subfields.first.value = "15.1"
      expect(subject["hlb3Delimited"]).not_to include("Humanities | Children's Literature")
    end
    it "includes interest age <= 18" do
      @record = hurdy_gurdy
      @record.append(interest_age)
      expect(subject["hlb3Delimited"]).to include("Humanities | Children's Literature")
    end
    it "does not include interest age > 18" do
      @record = hurdy_gurdy
      @record.append(interest_age)
      @record["521"].subfields.first.value = "18 and up"
      expect(subject["hlb3Delimited"]).not_to include("Humanities | Children's Literature")
    end
    it "includes interest grade <= 12" do
      @record = hurdy_gurdy
      @record.append(interest_grade)
      expect(subject["hlb3Delimited"]).to include("Humanities | Children's Literature")
    end
    it "does not include interest grade greater than 12" do
      @record = hurdy_gurdy
      @record.append(interest_grade)
      @record["521"].subfields.first.value = "13+"
      expect(subject["hlb3Delimited"]).not_to include("Humanities | Children's Literature")
    end
    it "handles multiple 521s where only one is true" do
      @record = hurdy_gurdy
      @record.append(interest_grade)
      @record.append(reading_grade)
      @record.append(interest_age)
      fields = @record.fields("521")
      fields.first.subfields.first.value = "13+"
      fields.last.subfields.first.value = "18 and up"
      expect(subject["hlb3Delimited"]).to include("Humanities | Children's Literature")
    end
    it "handles multiple 521s where only none are true" do
      @record = hurdy_gurdy
      @record.append(reading_grade)
      @record.append(interest_age)
      @record.append(interest_grade)
      fields = @record.fields("521")
      fields[0].subfields.first.value = "13.5"
      fields[1].subfields.first.value = "18 and up"
      fields[2].subfields.first.value = "13+"
      expect(subject["hlb3Delimited"]).not_to include("Humanities | Children's Literature")
    end
  end
end
