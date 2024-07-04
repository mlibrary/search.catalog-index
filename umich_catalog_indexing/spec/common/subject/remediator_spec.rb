require "common/subject"
RSpec.describe Common::Subject::Remediator do
  before(:each) do
    @mapping = [
      {
        "150" => [
          {"a" => "A"},
          {"x" => "X1"},
          {"x" => "X2"},
          {"v" => "V1"},
          {"v" => "V2"},
          {"y" => "Y1"},
          {"y" => "Y2"},
          {"z" => "Z1"},
          {"z" => "Z2"}
        ],
        "450" => [
          {"a" => "deprecated A"},
          {"x" => "deprecated X1"},
          {"x" => "deprecated X2"},
          {"v" => "deprecated V1"},
          {"v" => "deprecated V2"},
          {"y" => "deprecated Y1"},
          {"y" => "deprecated Y2"},
          {"z" => "deprecated Z1"},
          {"z" => "deprecated Z2"}
        ]
      }
    ]
  end
  let(:deprecated_field) do
    MARC::DataField.new("650", "0", "0",
      ["a", "deprecated A"],
      ["x", "deprecated X1"],
      ["x", "deprecated X2"],
      ["v", "deprecated V1"],
      ["v", "deprecated V2"],
      ["y", "deprecated Y1"],
      ["y", "deprecated Y2"],
      ["z", "deprecated Z1"],
      ["z", "deprecated Z2"])
  end
  subject do
    described_class.new(@mapping)
  end
  context "remediable?" do
    it "is true for a deprecated field field" do
      expect(subject.remediable?(deprecated_field)).to eq(true)
    end
    it "is false when any subfield doesn't match deprecated field" do
      @mapping[0]["450"][4] = {"v" => "something other deprecated v"}
      expect(subject.remediable?(deprecated_field)).to eq(false)
    end
    it "is true when the second mapping entity has the matching deprecated field" do
      @mapping.insert(0, {
        "150" => [{"a" => "blah"}],
        "450" => [{"a" => "whatever"}]
      })
      expect(subject.remediable?(deprecated_field)).to eq(true)
    end
  end
end
