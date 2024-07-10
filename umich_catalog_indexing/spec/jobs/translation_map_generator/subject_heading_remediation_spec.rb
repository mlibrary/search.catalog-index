require_relative "../../spec_helper"
require "jobs"

def remediated_term
  {"a" => ["Undocumented immigrants"]}
end

def deprecated_terms
  [
    {
      "a" => ["Aliens"],
      "x" => ["Legal status, laws, etc."]
    },
    {
      "a" => ["Illegal aliens"],
      "x" => ["Legal status, laws, etc."]
    },
    {
      "a" => ["Undocumented foreign nationals"]
    },
    {
      "a" => ["Illegal aliens"]
    },
    {
      "a" => ["Aliens, Illegal"]
    },
    {
      "a" => ["Illegal immigrants"]
    },
    {
      "a" => ["Undocumented noncitizens"]
    }
  ]
end
describe Jobs::TranslationMapGenerator::SubjectHeadingRemediation::Set do
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
      expect(subject.authority_records.first.remediated_term).to eq({"a" => ["Undocumented immigrants"]})
    end
  end

  context "#to_a" do
    it "returns an array of authority objects" do
      # Add an extra member to json
      d = JSON.parse(@data)
      d["member"].push({"id" => "999", "description" => "string"})
      @data = d.to_json
      stub_authority_request
      stub_second_authority_request

      expect(subject.to_a).to eq(
        [
          {
            "150" => remediated_term,
            "450" => deprecated_terms
          },
          {
            "150" => {
              "a" => ["Whatever"],
              "x" => ["First x field", "Second x field"],
              "v" => ["First v field", "Second v field"],
              "y" => ["First y field", "Second y field"],
              "z" => ["First z field", "Second z field"]
            },
            "450" => [
              {
                "a" => ["Stuff"],
                "x" => ["First deprecated x field", "Second deprecated x field"],
                "v" => ["First deprecated v field", "Second deprecated v field"],
                "y" => ["First deprecated y field", "Second deprecated y field"],
                "z" => ["First deprecated z field", "Second deprecated z field"]
              }
            ]
          }
        ]
      )
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
describe Jobs::TranslationMapGenerator::SubjectHeadingRemediation::Authority do
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
  context "#remediated_term" do
    it "returns the remediated term" do
      expect(subject.remediated_term).to eq(remediated_term)
    end
  end
  context "#deprecated_terms" do
    it "returns the deprecated terms from the 450 field" do
      expect(subject.deprecated_terms).to contain_exactly(*deprecated_terms)
    end
  end
  context "#to_h" do
    it "returns the expected deprecated_to_remediated hash with downcased terms" do
      expect(subject.to_h).to eq({
        "150" => remediated_term,
        "450" => deprecated_terms
      })
    end
  end
end
# describe Jobs::TranslationMapGenerator::SubjectHeadingRemediation::ToDeprecated do
# before(:each) do
# @data = {
# "illegal aliens" => "Undocumented immigrants",
# "aliens" => "Undocumented immigrants",
# "aliens, illegal" => "Undocumented immigrants",
# "illegal immigrants" => "Undocumented immigrants",
# "children of illegal aliens" => "Children of undocumented immigrants"
# }
# end
# context ".reverse_it" do
# it "reverses the input, using pipes as delimeters" do
# expect(described_class.reverse_it(@data)).to eq({
# "undocumented immigrants" => "illegal aliens||aliens||aliens, illegal||illegal immigrants",
# "children of undocumented immigrants" => "children of illegal aliens"
# })
# end
# end
# end
# describe Jobs::TranslationMapGenerator::SubjectHeadingRemediation::ToRemediated::Set do
# before(:each) do
# @data = fixture("authority_set.json")
# end
# let(:set_id) { "1234" }
# let(:authority_record_id) { "98187481368106381" }
# let(:authority_record) { fixture("remediated_authority_record.json") }
# let(:second_authority_record_id) { "999" }
# let(:second_authority_record) { fixture("remediated_authority_record2.json") }
# let(:stub_set_request) {
# stub_alma_get_request(
# url: "conf/sets/#{set_id}/members",
# query: {limit: 100, offset: 0},
# output: @data
# )
# }
# let(:stub_authority_request) {
# stub_alma_get_request(
# url: "bibs/authorities/#{authority_record_id}",
# query: {view: "full"},
# output: authority_record
# )
# }
# let(:stub_second_authority_request) {
# stub_alma_get_request(
# url: "bibs/authorities/#{second_authority_record_id}",
# query: {view: "full"},
# output: second_authority_record
# )
# }
# subject do
# described_class.new(JSON.parse(@data))
# end
# context "#ids" do
# it "returns an array of ids" do
# expect(subject.ids).to contain_exactly(authority_record_id)
# end
# end

# context "#authority_records" do
# it "returns an array of Authority objects" do
# stub_authority_request
# expect(subject.authority_records.first.remediated_term).to eq("Undocumented immigrants")
# end
# end

# context "#to_h" do
# it "returns a flattend hash of the array of authority objects" do
## Add an extra member to json
# d = JSON.parse(@data)
# d["member"].push({"id" => "999", "description" => "string"})
# @data = d.to_json
# stub_authority_request
# stub_second_authority_request

# expect(subject.to_h).to eq({
# "undocumented foreign nationals" => "Undocumented immigrants",
# "illegal aliens" => "Undocumented immigrants",
# "illegal aliens--legal status, laws, etc." => "Undocumented immigrants",
# "aliens--legal status, laws, etc." => "Undocumented immigrants",
# "aliens, illegal" => "Undocumented immigrants",
# "illegal immigrants" => "Undocumented immigrants",
# "undocumented noncitizens" => "Undocumented immigrants",
# "stuff--things--trivia" => "Whatever--Doesn't Matter--Another one"
# })
# end
# end
# context ".for" do
# it "returns a Set from the Alma Set id" do
# stub_set_request
# expect(described_class.for(set_id).ids.first).to eq(authority_record_id)
# end
# it "errors out if it can't talk to alma" do
# stub_alma_get_request(
# url: "conf/sets/#{set_id}/members",
# query: {limit: 100, offset: 0},
# no_return: true
# ).to_timeout
# expect { described_class.for(set_id) }.to raise_error(StandardError, /#{set_id}/)
# end
# end
# end
# describe Jobs::TranslationMapGenerator::SubjectHeadingRemediation::ToRemediated::Authority do
# before(:each) do
# @data = JSON.parse(fixture("remediated_authority_record.json"))
# end
# subject do
# described_class.new(@data)
# end
# let(:authority_record_id) { "12345" }
# context ".for" do
# it "errors out if it can't talk to Alma" do
# stub_alma_get_request(
# url: "bibs/authorities/#{authority_record_id}",
# query: {view: "full"},
# status: 500
# )
# expect { described_class.for(authority_record_id) }.to raise_error(StandardError, /#{authority_record_id}/)
# end
# end
# context "#remeidated_term" do
# it "returns the remediated term" do
# expect(subject.remediated_term).to eq("Undocumented immigrants")
# end
# end
# context "#deprecated_terms" do
# it "returns the deprecated terms from the 450 field" do
# expect(subject.deprecated_terms).to contain_exactly(
# "Undocumented foreign nationals",
# "Illegal aliens",
# "Aliens--Legal status, laws, etc.",
# "Aliens, Illegal",
# "Illegal immigrants",
# "Undocumented noncitizens"
# )
# end
# end
# context "#to_h" do
# it "returns the expected deprecated_to_remediated hash with downcased terms" do
# expect(subject.to_h).to eq({
# "undocumented foreign nationals" => "Undocumented immigrants",
# "illegal aliens" => "Undocumented immigrants",
# "aliens, legal status, laws, etc." => "Undocumented immigrants",
# "illegal aliens--legal status, laws, etc." => "Undocumented immigrants",
# "aliens, illegal" => "Undocumented immigrants",
# "illegal immigrants" => "Undocumented immigrants",
# "undocumented noncitizens" => "Undocumented immigrants"
# })
# end

# it "returns the hash with keys in reverse alphabetical order" do
# expect(subject.to_h.keys).to eq([
# "undocumented noncitizens",
# "undocumented foreign nationals",
# "illegal immigrants",
# "illegal aliens--legal status, laws, etc.",
# "illegal aliens",
# "aliens, legal status, laws, etc.",
# "aliens, illegal"
# ])
# end
# end
# end
