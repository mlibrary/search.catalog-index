require 'hathitrust/subject.rb'
require 'marc'
RSpec.describe HathiTrust::Subject do
  before(:each) do
    reader = MARC::XMLReader.new('./spec/fixtures/unauthorized_immigrants.xml')
    @record = nil
    for r in reader
      @record = r
    end
  end
  let(:subject_fields) do
    described_class.subject_fields(@record)
  end
  let(:lc_subject_field) do
    subject_fields.first
  end
  let(:non_lc_subject_field) do
    subject_fields[2]
  end
  context ".subject_field?" do
    it "returns true for appropriate subject field" do
      expect(described_class.subject_field?(lc_subject_field)).to eq(true)
    end
    it "returns false for field with incorrect tag" do
      not_subject = instance_double(MARC::DataField, tag: "800")
      expect(described_class.subject_field?(not_subject)).to eq(false)
    end
  end
  context ".lc_subject_field?" do
    it "returns true for appropriate subject field" do
      expect(described_class.lc_subject_field?(lc_subject_field)).to eq(true)
    end
    it "returns false for field with incorrect tag" do
      not_lc_subject = instance_double(MARC::DataField, tag: "600", indicator2: "1")
      expect(described_class.lc_subject_field?(not_lc_subject)).to eq(false)
    end
  end
  xcontext ".linked_fields_for" do
    it "returns a linking field?" do
    end
  end
  context ".subject_fields" do
    it "returns subject fields including non_lc" do
      subjects = described_class.subject_fields(@record)
      expect(subjects.first.tag).to eq("610")
      expect(subjects.count).to eq(4)
    end
    xit "returns subject fields and linked subject fields" do
    end
  end
  context ".lc_subject_fields" do
    it "returns just the lc_subject_fields" do
      subjects = described_class.lc_subject_fields(@record)
      expect(subjects.first.tag).to eq("610")
      expect(subjects.count).to eq(3)
    end
    xit "returns subject fields and linked subject fields" do
    end
  end
  context ".new" do
    it "returns an object that knows it's an LCSubject" do
      expect(described_class.new(lc_subject_field).lc_subject_field?).to eq(true)
    end
    it "returns an object that knows it's an Non LCSubject" do
      expect(described_class.new(non_lc_subject_field).lc_subject_field?).to eq(false)
    end
  end
end
