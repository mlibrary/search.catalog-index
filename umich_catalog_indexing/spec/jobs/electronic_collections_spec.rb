require_relative "../spec_helper.rb"
require "jobs"
RSpec.describe Jobs::ElectronicCollections::List do
  before(:each) do
    @collection = [
      {"0"=>"0",
        "E-Collection Bib - MMS Id"=>"99187703610206381",
        "Electronic Collection Level URL (override)"=>"OVERRIDE_URL",
        "Electronic Collection Level URL"=>"LEVEL_URL",
        "Electronic Collection Authentication Note"=>"AUTH_NOTE",
        "Electronic Collection Id"=>"611232981160006381",
        "Electronic Collection Interface Name (override)"=>"OVERRIDE_INTERFACE",
        "Electronic Collection Interface Name"=>"INTERFACE",
        "Electronic Collection Public Name (override)"=>"OVERRIDE_NAME",
        "Electronic Collection Public Name"=>"NAME",
        "Electronic Collection Public Note"=>"PUBLIC_NOTE"
      }
    ]
  end
  subject do
    described_class.new(@collection)
  end
  let(:expected_output) { 
        {
          "99187703610206381" =>
          [
            {
              "collection_name" => "OVERRIDE_NAME",
              "interface_name" => "OVERRIDE_INTERFACE",
              "note" => "AUTH_NOTE",
              "link" => "OVERRIDE_URL",
              "status" => "Available"
            }  
          ]
        }
  }
  context "#to_h" do
    it "returns a hash with a key of mms_id and a value of an array of hashes with
    collection info for the hol structure" do
      expect(subject.to_h).to eq(expected_output)
    end
    it "collapses duplicate items" do
      @collection[1] = @collection[0]
      expect(subject.to_h).to eq(expected_output)
    end
  end
end

RSpec.describe Jobs::ElectronicCollections::Item do
  before(:each) do
    @item = {
      "0"=>"0",
      "E-Collection Bib - MMS Id"=>"99187703610206381",
      "Electronic Collection Level URL (override)"=>"OVERRIDE_URL",
      "Electronic Collection Level URL"=>"LEVEL_URL",
      "Electronic Collection Authentication Note"=>"AUTH_NOTE",
      "Electronic Collection Id"=>"611232981160006381",
      "Electronic Collection Interface Name (override)"=>"OVERRIDE_INTERFACE",
      "Electronic Collection Interface Name"=>"INTERFACE",
      "Electronic Collection Public Name (override)"=>"OVERRIDE_NAME",
      "Electronic Collection Public Name"=>"NAME",
      "Electronic Collection Public Note"=>"PUBLIC_NOTE"
    }
  end
  subject do
    described_class.for(@item)
  end
  context "#mms_id" do
    it "returns the mms_id" do
      expect(subject.mms_id).to eq("99187703610206381")
    end
  end
  context "#collection_id" do
    it "returns the collection_id" do
      expect(subject.collection_id).to eq("611232981160006381")
    end
  end
  context "#link" do
    it "returns the override url if there is one" do
      expect(subject.link).to eq("OVERRIDE_URL")
    end
    it "returns the level url if there is no override url" do
      @item["Electronic Collection Level URL (override)"] = nil
      expect(subject.link).to eq("LEVEL_URL")
    end
    it "escapes the link" do
      @item["Electronic Collection Level URL (override)"] = "https://example.com/what is it"
      expect(subject.link).to eq("https://example.com/what%20is%20it")
    end
    it "handles nil level url and override url" do
      @item["Electronic Collection Level URL (override)"] = nil
      @item["Electronic Collection Level URL"] = nil
      expect(subject.link).to eq("")
    end
  end
  context "#status" do
    it "is 'Available' if there is a Level url" do
      expect(subject.status).to eq("Available")
    end
    it "is 'Not Available' if there is no level url" do
      @item["Electronic Collection Level URL (override)"] = nil
      @item["Electronic Collection Level URL"] = nil
      expect(subject.status).to eq("Not Available")
    end
  end
  context "#collection_name" do
    it "returns the Public Name (override) if there is one" do
      expect(subject.collection_name).to eq("OVERRIDE_NAME")
    end
    it "returns the Public Name if there isn't an override" do
      @item["Electronic Collection Public Name (override)"] = nil
      expect(subject.collection_name).to eq("NAME")
    end
  end
  context "#interface_name" do
    it "returns the Interface Name (override) if there is one" do
      expect(subject.interface_name).to eq("OVERRIDE_INTERFACE")
    end
    it "returns the Interface Name if there isn't an override" do
      @item["Electronic Collection Interface Name (override)"] = nil
      expect(subject.interface_name).to eq("INTERFACE")
    end
  end
  context "#note" do
    it "returns the Authentication note if it exists" do
      expect(subject.note).to eq("AUTH_NOTE")
    end
    it "returns the Public Note when there's no auth note and it exists" do
      @item["Electronic Collection Authentication Note"] = nil
      expect(subject.note).to eq("PUBLIC_NOTE")
    end
    it "returns the collection_name if there's no auth note and no public note" do
      @item["Electronic Collection Authentication Note"] = nil
      @item["Electronic Collection Public Note"] = nil
      expect(subject.note).to eq("OVERRIDE_NAME")
    end
    it "returns the interface name if there's no auth note or public note or collection name" do
      @item["Electronic Collection Authentication Note"] = nil
      @item["Electronic Collection Public Note"] = nil
      @item["Electronic Collection Public Name (override)"] = nil
      @item["Electronic Collection Public Name"] = nil
      expect(subject.note).to eq("OVERRIDE_INTERFACE")
    end
    it "returns nil if there's no note and no collection name and no interface name" do
      @item["Electronic Collection Authentication Note"] = nil
      @item["Electronic Collection Public Note"] = nil
      @item["Electronic Collection Public Name (override)"] = nil
      @item["Electronic Collection Public Name"] = nil
      @item["Electronic Collection Interface Name (override)"] = nil
      @item["Electronic Collection Interface Name"] = nil
      expect(subject.note).to eq(nil)
    end
  end
  context "#to_h" do
    it "returns expected hash values" do
      expect(subject.to_h).to eq({
        "collection_name" => "OVERRIDE_NAME",
        "interface_name" => "OVERRIDE_INTERFACE",
        "note" => "AUTH_NOTE",
        "link" => "OVERRIDE_URL",
        "status" => "Available"
      })
    end
  end

end
