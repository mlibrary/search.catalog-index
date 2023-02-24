require 'hathitrust/subject.rb'
require 'marc'
RSpec.describe HathiTrust::Subject::LCSubject do
  let(:record) do
    reader = MARC::XMLReader.new('./spec/fixtures/unauthorized_immigrants.xml')
    for r in reader
      return r
    end
  end
  let(:subject_field) do
    HathiTrust::Subject.lc_subject_fields(record).first
  end
  context "#subject_data_subfield_codes" do
    it "returns array of subfields with a-z codes" do
      subfields = described_class.new(subject_field).subject_data_subfield_codes
      expect(subfields.map{|sf| sf.code }).to eq(["a","t"])
    end
  end

  context "#subject_string" do
    it "puts a space between non v,x,y, or z subfields" do
      output = described_class.new(subject_field).subject_string
      expect(output).to eq("United States. Personal Responsibility and Work Opportunity Reconciliation Act of 1996")
    end
    it "puts a -- between v,x,y,or z subfields" do
      field = MARC::DataField.new( "600", "1", "0", 
        ["a", "a"], ["v", "v"], ["x", "x"], ["y", "y"], ["z", "z"], ["b","b"])

      output = described_class.new(field).subject_string
      expect(output).to eq("a--v--x--y--z b")
    end
  end
end

RSpec.describe HathiTrust::Subject::LCSubject658 do
  let(:subject_field) do
    MARC::DataField.new( "658", "1", "0", 
      ["a","Health objective 1"],
      ["b","handicapped awareness"],["c","NHP01-1991"],
      ["d", "highly correlated."],["2","ohco"]
    )
  end
  context "#subject_string" do
    it "returns expected output" do
      output = described_class.new(subject_field).subject_string
      expect(output).to eq("Health objective 1: handicapped awareness [NHP01-1991]--highly correlated. ")
    end
  end
end
RSpec.describe HathiTrust::Subject::LCSubjectHierarchical do
  let(:subject_field) do
    MARC::DataField.new( "662", "", "", 
      ["a","World"],
      ["a","Asia"],
      ["b","Japan"],
      ["g", "Hokkaido (island)"],
      ["g","Hokkaido (region)"],
      ["c","Hokkaido (prefecture)"],
      ["g","Asahi-Dake."],
      ["2","tgn"]
    )
  end
  context "#subject_string" do
    it "returns expected output" do
      output = described_class.new(subject_field).subject_string
      expect(output).to eq("World--Asia--Japan--Hokkaido (island)--Hokkaido (region)--Hokkaido (prefecture)--Asahi-Dake")
    end
  end
end
