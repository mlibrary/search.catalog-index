require "common/subject"
require "marc"
RSpec.describe Common::Subject do
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
    described_class.subject_fields(record)
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
  context ".subject_field?" do
    it "returns true for appropriate subject field" do
      expect(described_class.subject_field?(lc_subject_field)).to eq(true)
    end
    it "returns false for field with incorrect tag" do
      not_subject = instance_double(MARC::DataField, tag: "800")
      expect(described_class.subject_field?(not_subject)).to eq(false)
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

  context ".topics" do
    it "returns topics including remediated ones" do
      expect(described_class.topics(deprecated_record)).to contain_exactly(
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
      expect(described_class.topics(remediated_record)).to contain_exactly(
        "Undocumented immigrants.",
        "Emigration and immigration law.",
        "Noncitizens.",
        "Right to counsel.",
        "undocumented foreign nationals",
        "illegal aliens",
        "aliens",
        "aliens, illegal",
        "illegal immigrants",
        "undocumented noncitizens"
      )
    end
  end

  context ".remediated_subject_fields" do
    it "returns remediated a and z fields;adds indications that its been remediated" do
      d = deprecated_record
      d.fields("650").first.subfields.last.value = "Illegal aliens"
      subjects = described_class.remediated_subject_fields(d)
      expect(subjects[0].tag).to eq("650")
      expect(subjects[0].indicator2).to eq("7")
      expect(subjects[0]["a"]).to eq("Undocumented immigrants")
      expect(subjects[0]["x"]).to eq("Government policy")
      expect(subjects[0]["z"]).to eq("Undocumented immigrants")
      expect(subjects[0]["2"]).to eq("miush")
    end
  end
  context ".already_remediated_subject_fields" do
    it "returns the non_lcsh already remediated subject fields" do
      subjects = described_class.already_remediated_subject_fields(remediated_record)
      expect(subjects[0].tag).to eq("650")
      expect(subjects[0]["a"]).to eq("Undocumented immigrants.")
    end
  end

  context ".deprecated_subject_fields" do
    it "returns an array of all the deprecated subject fields" do
      r = remediated_record
      # adding repeatable field z to test if we get all deprecated fields
      r.fields("650")[2].append(MARC::Subfield.new("z", "Human smuggling"))
      r.fields("650")[2].append(MARC::Subfield.new("z", "Undocumented immigrant children"))
      fields = described_class.deprecated_subject_fields(r)
      filtered_fields = fields.map do |x|
        x.subfields.filter_map do |y|
          y.value if ["a", "z"].include?(y.code)
        end
      end.flatten
      expect(filtered_fields).to include(
        "undocumented foreign nationals",
        "illegal aliens",
        "aliens",
        "aliens, illegal",
        "illegal immigrants",
        "undocumented noncitizens",
        "immigrant smuggling",
        "migrant smuggling",
        "people smuggling",
        "undocumented foreign national children",
        "illegal alien children",
        "illegal immigrant children",
        "undocumented children",
        "undocumented child immigrants",
        "unaccompanied noncitizen children"
      )
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
