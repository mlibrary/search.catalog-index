require_relative "../../spec_helper"
require "jobs"

describe Jobs::TranslationMapGenerator::SubjectHeadingRemediation::ToRemediated::Authority do
  before(:each) do
    @data = JSON.parse(fixture("remediated_authority_record.json"))
  end
  subject do
    described_class.new(@data)
  end
  context "#remeidated_term" do
    it "returns the remediated term" do
      expect(subject.remediated_term).to eq("Undocumented immigrants")
    end
  end
  context "#deprecated_terms" do
    it "returns the deprecated terms" do
      expect(subject.deprecated_terms).to contain_exactly(
        "Undocumented foreign nationals",
        "Illegal aliens",
        "Aliens",
        "Aliens, Illegal",
        "Illegal immigrants",
        "Undocumented noncitizens",
        "Immigrant detention centers",
        "Human smuggling",
        "Noncitizens",
        "Illegal immigration"
      )
    end
  end
  context "#to_h" do
    it "returns the expected deprecated_to_remediated hash with downcased terms" do
      expect(subject.to_h).to eq({
        "undocumented foreign nationals" => "undocumented immigrants",
        "illegal aliens" => "undocumented immigrants",
        "aliens" => "undocumented immigrants",
        "aliens, illegal" => "undocumented immigrants",
        "illegal immigrants" => "undocumented immigrants",
        "undocumented noncitizens" => "undocumented immigrants",
        "immigrant detention centers" => "undocumented immigrants",
        "human smuggling" => "undocumented immigrants",
        "noncitizens" => "undocumented immigrants",
        "illegal immigration" => "undocumented immigrants"
      })
    end
  end
end
