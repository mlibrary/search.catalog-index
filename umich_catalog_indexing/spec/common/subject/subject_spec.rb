require "common/subjects"
RSpec.describe Common::Subjects::Subject do
  def get_record(path)
    MARC::XMLReader.new(path).first
  end
  let(:record) do
    get_record("./spec/fixtures/unauthorized_immigrants.xml")
  end
  let(:subject_fields) do
    Common::Subjects.subject_fields(record)
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

  context ".new" do
    it "returns an object that knows it's an LCSubject" do
      expect(described_class.new(lc_subject_field).lc_subject_field?).to eq(true)
    end
    it "returns an object that knows it's an Non LCSubject" do
      expect(described_class.new(non_lc_subject_field).lc_subject_field?).to eq(false)
    end
  end
end
