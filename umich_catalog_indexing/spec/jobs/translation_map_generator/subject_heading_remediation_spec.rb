require_relative "../../spec_helper"
require "jobs"

def remediated_term
  {"a" => ["Undocumented immigrants"]}
end

def geo_remediated_term
  {"a" => ["Mexico, Gulf of, Watershed"]}
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

def geo_deprecated_terms
  [
    {
      "a" => ["America, Gulf of, Watershed"]
    },
    {
      "a" => ["Test Test Test"]
    }
  ]
end
describe Jobs::TranslationMapGenerator::SubjectHeadingRemediation::Set do
  before(:each) do
    @data = fixture("subjects/authority_set.json")
  end
  let(:set_id) { "1234" }
  let(:authority_record_id) { "98187481368106381" }
  let(:authority_record) { fixture("subjects/authority_record.json") }
  let(:second_authority_record_id) { "999" }
  let(:second_authority_record) { fixture("subjects/authority_record2.json") }
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
  let(:geo_authority_record) { JSON.parse(fixture("subjects/geo_authority_record.json")) }
  before(:each) do
    @data = JSON.parse(fixture("subjects/authority_record.json"))
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
    it "returns the remediated term in the 150" do
      expect(subject.remediated_term).to eq(remediated_term)
    end
    it "returns the remediated term in the 151" do
      @data = geo_authority_record
      expect(subject.remediated_term).to eq(geo_remediated_term)
    end
  end
  context "#deprecated_terms" do
    it "returns the deprecated terms from the 450 field" do
      expect(subject.deprecated_terms).to contain_exactly(*deprecated_terms)
    end
    it "returns the deprecated terms from the 451 field" do
      @data = geo_authority_record
      expect(subject.deprecated_terms).to contain_exactly(*geo_deprecated_terms)
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
