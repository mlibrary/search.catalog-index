require_relative '../spec_helper.rb'
require 'jobs'
RSpec.describe Jobs::Utilities::ZephirFile do
  before(:each) do
    @today = DateTime.parse("20210212") 
  end
  context "#latest_monthly_full" do
    it "returns the correct string" do
      expect(described_class.latest_monthly_full(@today)).to eq("zephir_full_20210131_vufind.json.gz")
    end
  end
  context "latest_daily_update" do
    it "returns the correct string" do
      expect(described_class.latest_daily_update(@today)).to eq("zephir_upd_20210211.json.gz")
    end
  end
  context "daily_update" do
    it "returns the correct string" do
      expect(described_class.daily_update(@today)).to eq("zephir_upd_20210211.json.gz")
    end
  end
end

