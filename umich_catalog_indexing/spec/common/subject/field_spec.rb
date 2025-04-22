require "common/subjects"
RSpec.describe Common::Subjects::Field do
  before(:each) do
    @field = remediated_field
    @source = "zephir"
    @mapping = [
      {
        "1xx" => {
          "a" => ["A"],
          "x" => ["X1", "X2"],
          "v" => ["V1", "V2"],
          "y" => ["Y1", "Y2"],
          "z" => ["Z1", "Z2"]
        },
        "4xx" => [
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
    MARC::DataField.new("650", "0", "7",
      ["a", "A"],
      ["v", "V1"],
      ["v", "V2"],
      ["x", "X1"],
      ["x", "X2"],
      ["y", "Y1"],
      ["y", "Y2"],
      ["z", "Z1"],
      ["z", "Z2"],
      ["2", "miush"])
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
  def _normalize_sf(str)
    str&.downcase&.gsub(/[^A-Za-z0-9\s]/i, "")
  end
  let(:normalized_sfs) do
    @field.subfields.map do |sf|
      {"code" => sf.code, "value" => _normalize_sf(sf.value)}
    end
  end
  subject do
    map = Common::Subjects::RemediationMap.new(@mapping)
    described_class.new(field: @field, remediation_map: map, normalized_sfs: normalized_sfs, source: @source)
  end
  context "remediable?" do
    before(:each) do
      @field = deprecated_field
    end
    context "alma record" do
      it "is false" do
        # Alma records should already have remediated fields
        @source = "alma"
        expect(subject.remediable?).to eq(false)
      end
    end
    context "zephir record" do
      it "is true for a deprecated field" do
        expect(subject.remediable?).to eq(true)
      end
      it "is false when any subfield doesn't match deprecated field" do
        @mapping[0]["4xx"][0]["v"][1] = "something other deprecated v"
        expect(subject.remediable?).to eq(false)
      end
      it "is true when the second mapping entity has the matching deprecated field" do
        @mapping.insert(0, {
          "1xx" => {"a" => ["blah"]},
          "4xx" => [{"a" => ["whatever"]}]
        })
        expect(subject.remediable?).to eq(true)
      end
      it "is true when the deprecated field has extra subfields" do
        @field.append(MARC::Subfield.new("z", "Whatever"))
        expect(subject.remediable?).to eq(true)
      end
    end
  end
  context "to_remediated" do
    it "returns the remediated version of the field" do
      @field = deprecated_field
      expect(subject.to_remediated).to eq(remediated_field)
    end
    it "matches deprecated fields with extra periods and different capitalization" do
      @field = deprecated_field
      @field.subfields[0].value = "Deprecated A."
      expect(subject.to_remediated).to eq(remediated_field)
    end
    it "has a 0 indicator 7 and a 2 miush" do
      @field = deprecated_field
      rem_field = subject.to_remediated
      expect(rem_field.indicator2).to eq("7")
      expect(rem_field["2"]).to eq("miush")
    end
  end

  context "already_remediated?" do
    context "missing miush subfield 2" do
      it "returns false" do
        remediated_field.subfields.pop
        expect(subject.already_remediated?).to eq(false)
      end
    end
    context "has miush subfield 2" do
      it "returns true when there is a matching already remediated field" do
        expect(subject.already_remediated?).to eq(true)
      end
      it "returns false when it is missing a subfield" do
        @mapping[0]["1xx"]["v"][1] = "something other than v"
        expect(subject.already_remediated?).to eq(false)
      end
      it "returns true when the matching field has an extra field" do
        @field.append(MARC::Subfield.new("z", "Whatever"))
        expect(subject.already_remediated?).to eq(true)
      end
      it "is true when the second mapping entity has the matching remediated field" do
        @mapping.insert(0, {
          "1xx" => {"a" => ["blah"]},
          "4xx" => [{"a" => ["whatever"]}]
        })
        expect(subject.already_remediated?).to eq(true)
      end
    end
  end
  context "to_deprecated(field)" do
    it "returns an array of deprecated fields" do
      deprecated_field.indicator2 = "7"
      deprecated_field.append(MARC::Subfield.new("2", "miush"))
      expect(subject.to_deprecated).to eq([deprecated_field])
    end
  end
end
