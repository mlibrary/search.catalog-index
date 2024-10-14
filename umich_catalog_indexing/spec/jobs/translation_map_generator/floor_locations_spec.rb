require_relative "../../spec_helper"
require "jobs"
RSpec.describe Jobs::TranslationMapGenerator::FloorLocations::FloorLocation do
  before(:each) do
    @data = [
      "HATCH",
      "GRAD",
      "AC - AM",
      "",
      "http://www.lib.umich.edu/library-floor-plan/graduate-library-north-first-floor-0",
      "1N",
      "1 North"
    ]
  end
  subject do
    described_class.new(@data)
  end
  it "has a library code" do
    expect(subject.library).to eq("HATCH")
  end
  it "has a location code" do
    expect(subject.location).to eq("GRAD")
  end
  it "has a code" do
    expect(subject.code).to eq("1N")
  end
  it "has text" do
    expect(subject.text).to eq("1 North")
  end
  context "#start" do
    it "has downcased, plain string when it's just a letter version" do
      expect(subject.start).to eq("ac")
    end
    it "collapses spaces and adds .00000 to the end when the given value ends in a number" do
      @data[2] = "HD 8000 - HE"
      expect(subject.start).to eq("hd8000.00000")
    end
    it "handles Music call numbers" do
      @data[0] = "MUSIC"
      @data[2] = "ML 5 .M8445 - Z"
      expect(subject.start).to eq("ml0005.00000.m8445")
    end
    it "handles Asia call numbers" do
      @data[1] = "ASIA"
      @data[2] = "DS 856.72 - DX"
      expect(subject.start).to eq("ds0856.72000")
    end
    it "handles Dewey call number" do
      @data[2] = "350"
      expect(subject.start).to eq(350)
    end
    it "handles empty string call number" do
      @data[2] = ""
      expect(subject.start).to be_nil
    end
  end
  context "#stop" do
    it "has downcased, plain string ending in 'z' when it's just a letter version" do
      expect(subject.stop).to eq("amz")
    end
    it "returns the same as start with z when only one letter range" do
      @data[2] = "F"
      expect(subject.stop).to eq("fz")
    end
    it "handles Dewey call numbers" do
      @data[2] = "350"
      expect(subject.stop).to eq(350.9999)
    end
    it "handles Music call numbers" do
      @data[0] = "MUSIC"
      @data[2] = "ML 1 - ML 5 .M8443"
      expect(subject.stop).to eq("ml0005.00000.m8443z")
      expect(subject.start).to eq("ml0001.00000")
    end
    it "handles Asia call numbers" do
      @data[1] = "ASIA"
      @data[2] = "D - DS 856.7"
      expect(subject.start).to eq("d")
      expect(subject.stop).to eq("ds0856.70000z")
    end
    it "handles call numbers that end in numbers" do
      @data[2] = "Z 1 - Z 1199"
      expect(subject.stop).to eq("z1199.00000z")
    end
    it "handles empty string call number" do
      @data[2] = ""
      expect(subject.stop).to be_nil
    end
    it "handles LC call numbers that start with digit less than 100" do
      @data[2] = "Z 1 - Z 1199"
      expect(subject.start).to eq("z0001.00000")
    end
  end

  context "#type" do
    it "is LC by default" do
      expect(subject.type).to eq("LC")
    end
    it "is Dewey when call number starts with a digit" do
      @data[2] = "350"
      expect(subject.type).to eq("Dewey")
    end
    it "is Everything when call_number is an empty string" do
      @data[2] = ""
      expect(subject.type).to eq("Everything")
    end
  end

  context "#_to_h" do
    it "returns a hash version of the floor location" do
      expect(subject.to_h).to eq({
        "library" => "HATCH",
        "collection" => "GRAD",
        "start" => "ac",
        "stop" => "amz",
        "floor_key" => "1N",
        "text" => "1 North",
        "type" => "LC"
      })
    end
  end
end
