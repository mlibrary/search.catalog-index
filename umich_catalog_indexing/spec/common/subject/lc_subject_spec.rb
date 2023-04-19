require 'common/subject.rb'
require 'marc'

RSpec.describe Common::Subject::LCSubject do
  let(:record) do
    MARC::XMLReader.new('./spec/fixtures/unauthorized_immigrants.xml').first
  end
  let(:subject_fields) do
    Common::Subject.only_lc_subject_fields(record)
  end
  let(:subject_field) do
    subject_fields.first
  end
  let(:non_lc_subject_field) do
    subject_fields[2]
  end
  let(:wrongindicator_subject_field) do
    MARC::DataField.new("650", "0", "0", ["a", "subjectA"], ["2", "gnd"])
  end
  context ".lc_subject_field?" do
    it "returns true for appropriate subject field" do
      expect(described_class.lc_subject_field?(subject_field)).to eq(true)
    end
    it "returns false for field with incorrect tag" do
      not_lc_subject = instance_double(MARC::DataField, tag: "600", indicator2: "1")
      expect(described_class.lc_subject_field?(not_lc_subject)).to eq(false)
    end
    it "returns false for a field with ind2=0 but a $2 that says otherwise" do
      expect(described_class.lc_subject_field?(wrongindicator_subject_field)).to eq(false)
    end
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

RSpec.describe Common::Subject::LCSubject658 do
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
      expect(output).to eq("Health objective 1: handicapped awareness [NHP01-1991]--highly correlated")
    end
  end
end
RSpec.describe Common::Subject::LCSubjectHierarchical do
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
