require "common/subjects"
RSpec.describe Common::Subjects::Field do
  before(:each) do
    @field = remediated_field
    @mapping = [
      {
        "150" => {
          "a" => ["A"],
          "x" => ["X1", "X2"],
          "v" => ["V1", "V2"],
          "y" => ["Y1", "Y2"],
          "z" => ["Z1", "Z2"]
        },
        "450" => [
          {
            "a" => ["deprecated A"],
            "x" => ["deprecated X1", "deprecated X2"],
            "v" => ["deprecated V1", "deprecated V2"],
            "y" => ["deprecated Y1", "deprecated Y2"],
            "z" => ["deprecated Z1", "deprecated Z2"]
          }
        ]
      }
    ]
  end
  let(:remediated_field) do
    MARC::DataField.new("650", "0", "0",
      ["a", "A"],
      ["v", "V1"],
      ["v", "V2"],
      ["x", "X1"],
      ["x", "X2"],
      ["y", "Y1"],
      ["y", "Y2"],
      ["z", "Z1"],
      ["z", "Z2"])
  end
  let(:miush_remediated_field) do
    rem = remediated_field
    rem.indicator2 = "7"
    rem.append(MARC::Subfield.new("2", "miush"))
    rem
  end
  let(:deprecated_field) do
    MARC::DataField.new("650", "0", "0",
      ["a", "deprecated A"],
      ["v", "deprecated V1"],
      ["v", "deprecated V2"],
      ["x", "deprecated X1"],
      ["x", "deprecated X2"],
      ["y", "deprecated Y1"],
      ["y", "deprecated Y2"],
      ["z", "deprecated Z1"],
      ["z", "deprecated Z2"])
  end
  let(:normalized_sfs) do
    @field.subfields.filter_map do |sf|
      {"code" => sf.code, "value" => Common::Subjects::Remediator.normalize_sf(sf.value)}
    end
  end
  subject do
    map = Common::Subjects::RemediationMap.new(@mapping)
    described_class.new(field: @field, normalized_sfs: normalized_sfs, remediation_map: map)
  end
  context "remediable?" do
    it "is true for a deprecated field" do
      @field = deprecated_field
      expect(subject.remediable?).to eq(true)
    end
    it "is false when any subfield doesn't match deprecated field" do
      @mapping[0]["450"][0]["v"][1] = "something other deprecated v"
      expect(subject.remediable?).to eq(false)
    end
    it "is true when the second mapping entity has the matching deprecated field" do
      @mapping.insert(0, {
        "150" => {"a" => ["blah"]},
        "450" => [{"a" => ["whatever"]}]
      })
      @field = deprecated_field
      expect(subject.remediable?).to eq(true)
    end
    it "is true when the deprecated field has extra subfields" do
      @field = deprecated_field
      @field.append(MARC::Subfield.new("z", "Whatever"))
      expect(subject.remediable?).to eq(true)
    end
  end
  context "to_remediated" do
    it "returns the remediated version of the field" do
      @field = deprecated_field
      expect(subject.to_remediated).to eq(miush_remediated_field)
    end
    it "matches deprecated fields with extra periods and different capitalization" do
      @field = deprecated_field
      @field.subfields[0].value = "Deprecated A."
      expect(subject.to_remediated).to eq(miush_remediated_field)
    end
    it "has a 0 indicator 7 and a 2 miush" do
      @field = deprecated_field
      rem_field = subject.to_remediated
      expect(rem_field.indicator2).to eq("7")
      expect(rem_field["2"]).to eq("miush")
    end
  end

  context "already_remediated?" do
    it "returns true when there is a matching already remediated field" do
      expect(subject.already_remediated?).to eq(true)
    end
    it "returns false when it is missing a subfield" do
      @mapping[0]["150"]["v"][1] = "something other than v"
      expect(subject.already_remediated?).to eq(false)
    end
    it "returns true when the matching field has an extra field" do
      @field.append(MARC::Subfield.new("z", "Whatever"))
      expect(subject.already_remediated?).to eq(true)
    end
    it "is true when the second mapping entity has the matching remediated field" do
      @mapping.insert(0, {
        "150" => {"a" => ["blah"]},
        "450" => [{"a" => ["whatever"]}]
      })
      expect(subject.already_remediated?).to eq(true)
    end
  end
  context "to_deprecated(field)" do
    it "returns an array of deprecated fields" do
      expect(subject.to_deprecated).to eq([deprecated_field])
    end
  end
end
