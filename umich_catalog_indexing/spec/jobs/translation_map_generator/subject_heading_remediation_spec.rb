require_relative "../../spec_helper"
require "jobs"

describe Jobs::TranslationMapGenerator::SubjectHeadingRemediation::ToRemediated::Set do
  before(:each) do
    @data = fixture("authority_set.json")
  end
  let(:set_id) { "1234" }
  let(:authority_record_id) { "98187481368106381" }
  let(:authority_record) { fixture("remediated_authority_record.json") }
  let(:second_authority_record_id) { "999" }
  let(:second_authority_record) { fixture("remediated_authority_record2.json") }
  let(:stub_set_request) {
    stub_alma_get_request(
      url: "conf/sets/#{set_id}/members",
      query: {limit: 100, offset: 0},
      output: @data
    )
  }
  let(:stub_authority_request) {
    stub_alma_get_request(
      url: "bibs/authorities/#{authority_record_id}",
      query: {view: "full"},
      output: authority_record
    )
  }
  let(:stub_second_authority_request) {
    stub_alma_get_request(
      url: "bibs/authorities/#{second_authority_record_id}",
      query: {view: "full"},
      output: second_authority_record
    )
  }
  subject do
    described_class.new(JSON.parse(@data))
  end
  context "#ids" do
    it "returns an array of ids" do
      expect(subject.ids).to contain_exactly(authority_record_id)
    end
  end

  context "#authority_records" do
    it "returns an array of Authority objects" do
      stub_authority_request
      expect(subject.authority_records.first.remediated_term).to eq("Undocumented immigrants")
    end
  end

  context "#to_h" do
    it "returns a flattend hash of the array of authority objects" do
      # Add an extra member to json
      d = JSON.parse(@data)
      d["member"].push({"id" => "999", "description" => "string"})
      @data = d.to_json
      stub_authority_request
      stub_second_authority_request

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
        "illegal immigration" => "undocumented immigrants",
        "stuff" => "whatever"
      })
    end
  end
  context ".for" do
    it "returns a Set from the Alma Set id" do
      stub_set_request
      expect(described_class.for(set_id).ids.first).to eq(authority_record_id)
    end
    it "errors out if it can't talk to alma" do
      stub_alma_get_request(
        url: "conf/sets/#{set_id}/members",
        query: {limit: 100, offset: 0},
        no_return: true
      ).to_timeout
      expect { described_class.for(set_id) }.to raise_error(StandardError, /#{set_id}/)
    end
  end
end
describe Jobs::TranslationMapGenerator::SubjectHeadingRemediation::ToRemediated::Authority do
  before(:each) do
    @data = JSON.parse(fixture("remediated_authority_record.json"))
  end
  subject do
    described_class.new(@data)
  end
  let(:authority_record_id) { "12345" }
  context ".for" do
    it "errors out if it can't talk to Alma" do
      stub_alma_get_request(
        url: "bibs/authorities/#{authority_record_id}",
        query: {view: "full"},
        status: 500
      )
      expect { described_class.for(authority_record_id) }.to raise_error(StandardError, /#{authority_record_id}/)
    end
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
