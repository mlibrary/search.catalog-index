require "common/subject"
require "marc"
RSpec.describe Common::Subjects do
  def get_record(path)
    MARC::XMLReader.new(path).first
  end
  let(:record) do
    get_record("./spec/fixtures/unauthorized_immigrants.xml")
  end
  let(:deprecated_record) do
    get_record("./spec/fixtures/deprecated_subject.xml")
  end
  let(:remediated_record) do
    get_record("./spec/fixtures/remediated_subject.xml")
  end
  let(:record_with_880) do
    get_record("./spec/fixtures/subject_with_880.xml")
  end
  let(:subject_fields) do
    subject.subject_fields
  end
  let(:lc_subject_field) do
    subject_fields.first
  end
  let(:non_lc_subject_field) do
    subject_fields[2]
  end
  let(:wrongindicator_subject_field) do
    MARC::DataField.new("650", "0", "0", ["a", "subjectA"], ["2" "gnd"])
  end
  before(:each) do
    @record = record
  end
  subject do
    described_class.new(@record)
  end
  context "with all class methods" do
    context ".subject_field?" do
      it "returns true for appropriate subject field" do
        expect(described_class.subject_field?(lc_subject_field)).to eq(true)
      end
      it "returns false for field with incorrect tag" do
        not_subject = instance_double(MARC::DataField, tag: "800")
        expect(described_class.subject_field?(not_subject)).to eq(false)
      end
    end

    context ".for" do
      it "returns an object that knows it's an LCSubject" do
        expect(described_class.for(lc_subject_field).lc_subject_field?).to eq(true)
      end
      it "returns an object that knows it's an Non LCSubject" do
        expect(described_class.for(non_lc_subject_field).lc_subject_field?).to eq(false)
      end
    end
  end
  context "instance methods" do
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

    context "#_linked_fields_for" do
      it "returns a linking field?" do
        @record = record_with_880
        field = @record["630"]
        linked_fields = subject._linked_fields_for(field)
        expect(linked_fields.first.value).to eq("630-05/大武經.")
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

    context "#deprecated_subject_fields" do
      it "returns an array of all the deprecated subject fields" do
        @record = remediated_record
        # adding repeatable field z to test if we get all deprecated fields
        fields = subject.deprecated_subject_fields
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
    context "#remediated_subject_fields" do
      it "returns remediated fields;adds indications that its been remediated" do
        @record = deprecated_record
        subjects = subject.remediated_subject_fields
        expect(subjects[0].tag).to eq("650")
        expect(subjects[0].indicator2).to eq("7")
        expect(subjects[0]["a"]).to eq("Undocumented immigrants")
        expect(subjects[0]["2"]).to eq("miush")
      end
    end
    context "#remediated_lc_subject_fields" do
      it "includes already remediated terms" do
        subjects = subject.remediated_lc_subject_fields
        expect(subjects.count).to eq(1)
      end
      it "includes newly remediated terms" do
        @record = deprecated_record
        subjects = subject.remediated_lc_subject_fields
        expect(subjects.count).to eq(2)
      end
    end
    xcontext "#subject_browse_fields" do
      it "does something" do
      end
    end
    context "#topics" do
      it "returns topics including remediated ones" do
        @record = deprecated_record
        expect(subject.topics).to contain_exactly(
          "United States",
          "United States Emigration and immigration Government policy.",
          "Illegal aliens",
          "Illegal aliens Government policy United States.",
          "Illegal aliens United States.",
          "Undocumented immigrants",
          "Undocumented immigrants Government policy United States.",
          "Undocumented immigrants United States."
        )
      end

      it "returns topics including deprecated ones" do
        @record = remediated_record
        expect(subject.topics).to contain_exactly(
          "Noncitizens.",
          "Emigration and immigration law.",
          "Undocumented immigrants.",
          "Right to counsel.",
          "Aliens",
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
    context "#subject_facets" do
      it "returns topics including remediated ones, skips unremediated ones" do
        @record = deprecated_record
        expect(subject.subject_facets).to contain_exactly(
          "United States",
          "United States Emigration and immigration Government policy.",
          "Undocumented immigrants",
          "Undocumented immigrants Government policy United States.",
          "Undocumented immigrants United States."
        )
      end

      it "returns topics, does nothing with already remediated records" do
        @record = remediated_record
        expect(subject.subject_facets).to contain_exactly(
          "Undocumented immigrants.",
          "Emigration and immigration law.",
          "Noncitizens.",
          "Right to counsel."
        )
      end
    end
  end
end
