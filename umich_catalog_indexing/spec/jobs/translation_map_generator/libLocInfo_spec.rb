require "yaml"
require_relative "../../spec_helper"
require "jobs"
RSpec.describe Jobs::TranslationMapGenerator::LibLocInfo::LibraryLocationList, "#list" do
  before(:each) do
    @libraries = JSON.parse(fixture("/aael.json"))
    @locations = JSON.parse(fixture("/aael_locations_short.json"))
    @output = YAML.load_file("spec/fixtures/libLocShort.yaml")
  end
  subject do
    stub_alma_get_request(url: "conf/libraries", output: @libraries.to_json)
    stub_alma_get_request(url: "conf/libraries/AAEL/locations", output: @locations.to_json)
    described_class.new.list
  end
  it "returns expected yaml" do
    expect(subject).to eq(@output)
  end
  it "handles NONE location name" do
    @locations["location"][0]["name"] = "NONE"
    @locations["location"][0]["external_name"] = "NONE"
    @output["AAEL DISP"]["name"] = "Art Architecture & Engineering"
    expect(subject).to eq(@output)
  end
  it "handles UNASSIGNED location" do
    @locations["location"][0]["name"] = "UNASSIGNED location"
    @locations["location"][0]["external_name"] = ""
    @output["AAEL DISP"]["name"] = "Art Architecture & Engineering"
    expect(subject).to eq(@output)
  end
  it "picks external name over internal name" do
    @locations["location"][0]["external_name"] = "External Name"
    @output["AAEL DISP"]["name"] = "Art Architecture & Engineering External Name"
    expect(subject).to eq(@output)
  end
  it "doesn't print location code as display name when its the external name" do
    @locations["location"][0]["external_name"] = "DISP"
    @output["AAEL DISP"]["name"] = "Art Architecture & Engineering"
    expect(subject).to eq(@output)
  end
  it "doesn't print location code as display name when its the internal name" do
    @locations["location"][0]["external_name"] = ""
    @locations["location"][0]["name"] = "DISP"
    @output["AAEL DISP"]["name"] = "Art Architecture & Engineering"
    expect(subject).to eq(@output)
  end
  it "doesn't print location code if it's the internal name and not upcased" do
    @locations["location"][0]["external_name"] = ""
    @locations["location"][0]["name"] = "DiSp"
    @output["AAEL DISP"]["name"] = "Art Architecture & Engineering"
    expect(subject).to eq(@output)
  end
  it "skips numerical locations" do
    @locations["location"][0]["code"] = "9999"
    expect(subject.keys.count).to eq(1)
  end
end
