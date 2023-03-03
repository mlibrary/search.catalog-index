require 'common/subject.rb'
require 'marc'
RSpec.describe Common::Subject do
  def get_record(path) 
    reader = MARC::XMLReader.new(path)
    for r in reader
      return r
    end
  end
  let(:record) do
    get_record('./spec/fixtures/unauthorized_immigrants.xml')
  end
  let(:record_with_880) do
    get_record('./spec/fixtures/subject_with_880.xml')
  end
  let(:subject_fields) do
    described_class.subject_fields(record)
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
  context ".linked_fields_for" do
    it "returns a linking field?" do
      rec = record_with_880
      field = rec["630"]
      linked_fields = described_class.linked_fields_for(record_with_880, field)
      expect(linked_fields.first.value).to eq("630-05/大武經.")

    end
  end
  context ".subject_fields" do
    it "returns subject fields including non_lc" do
      subjects = described_class.subject_fields(record)
      expect(subjects.first.tag).to eq("610")
      expect(subjects.count).to eq(4)
    end
    it "returns subject fields and linked subject fields" do
      subjects = described_class.subject_fields(record_with_880)
      expect(subjects[0].tag).to eq("630")
      expect(subjects[3].tag).to eq("880")
      expect(subjects.count).to eq(4)
    end
  end
  context ".lc_subject_fields" do
    it "returns just the lc_subject_fields" do
      subjects = described_class.lc_subject_fields(record)
      expect(subjects.first.tag).to eq("610")
      expect(subjects.count).to eq(3)
    end
    it "returns subject fields and linked subject fields" do
      subjects = described_class.lc_subject_fields(record_with_880)
      expect(subjects[0].tag).to eq("630")
      expect(subjects[3].tag).to eq("880")
      expect(subjects.count).to eq(4)
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
