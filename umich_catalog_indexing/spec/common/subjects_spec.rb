require "common/subjects"
require "marc"
RSpec.describe Common::Subjects do
  def get_record(path)
    MARC::XMLReader.new(path).first
  end
  let(:record) do
    get_record("./spec/fixtures/unauthorized_immigrants.xml")
  end
  let(:record_with_880) do
    get_record("./spec/fixtures/subject_with_880.xml")
  end

  let(:deprecated_record) do
    get_record("./spec/fixtures/subjects/deprecated_subject.xml")
  end

  let(:remediated_record) do
    get_record("./spec/fixtures/subjects/remediated_subject.xml")
  end

  before(:each) do
    @record = record
  end
  subject do
    described_class.new(@record)
  end
  context "#lc_subjects" do
    it "returns an array of lc subject strings" do
      s = subject.lc_subjects
      expect(s.count).to eq(3)
      expect(s.first).to eq("United States. Personal Responsibility and Work Opportunity Reconciliation Act of 1996")
    end
  end
  context "#non_lc_subjects" do
    it "returns an array of non lc subject strings" do
      s = subject.non_lc_subjects
      expect(s.count).to eq(1)
      expect(s.first).to eq("Undocumented immigrants--United States")
    end
  end

  context "#subject_fields" do
    it "returns subject fields including non_lc" do
      subjects = subject.subject_fields
      expect(subjects.first.tag).to eq("610")
      expect(subjects.count).to eq(4)
    end
    it "returns subject fields and linked subject fields" do
      @record = record_with_880
      subjects = subject.subject_fields
      expect(subjects[0].tag).to eq("630")
      expect(subjects[3].tag).to eq("880")
      expect(subjects.count).to eq(4)
    end
  end

  context "#lc_subject_fields" do
    it "returns just the lc_subject_fields" do
      subjects = subject.lc_subject_fields
      expect(subjects.first.tag).to eq("610")
      expect(subjects.count).to eq(3)
    end
    it "returns subject fields and linked subject fields" do
      @record = record_with_880
      subjects = subject.lc_subject_fields
      expect(subjects[0].tag).to eq("630")
      expect(subjects[3].tag).to eq("880")
      expect(subjects.count).to eq(4)
    end
  end
  context "#newly_deprecated_subject_fields" do
    it "returns an array of all the deprecated subject fields" do
      @record = remediated_record
      # adding repeatable field z to test if we get all deprecated fields
      fields = subject.newly_deprecated_subject_fields
      filtered_fields = fields.map do |x|
        x.subfields.filter_map do |y|
          y.value if ["a", "v", "x", "y", "z"].include?(y.code)
        end.join(" ")
      end.flatten
      expect(filtered_fields).to contain_exactly(
        "Aliens Legal status, laws, etc.",
        "Illegal aliens",
        "Illegal aliens Legal status, laws, etc.",
        "Undocumented foreign nationals",
        "Aliens, Illegal",
        "Illegal immigrants",
        "Undocumented noncitizens"
      )
    end
  end
  context "#already_remediated_subject_fields" do
    it "returns the non_lcsh already remediated subject fields" do
      @record = remediated_record
      subjects = subject.already_remediated_subject_fields
      expect(subjects[0].tag).to eq("650")
      expect(subjects[0]["a"]).to eq("Undocumented immigrants.")
    end
  end
  context "#newly_remediated_subject_fields" do
    it "returns remediated fields;adds indications that its been remediated" do
      @record = deprecated_record
      subjects = subject.newly_remediated_subject_fields
      expect(subjects[0].tag).to eq("650")
      expect(subjects[0].indicator2).to eq("7")
      expect(subjects[0]["a"]).to eq("Undocumented immigrants")
      expect(subjects[0]["2"]).to eq("miush")
    end
  end
  context "#_linked_fields_for" do
    it "returns a linking field?" do
      @record = record_with_880
      field = @record["630"]
      linked_fields = subject._linked_fields_for(field)
      expect(linked_fields.first.value).to eq("630-05/大武經.")
    end
  end
end
