require "traject"
require "umich_traject"
describe Traject::UMich::PhysicalHoldings do
  let(:offsite) do
    get_record("./spec/fixtures/hsrs_one_item.xml")
  end
  let(:holding_data) { offsite.fields.find { |f| f["8"] == holding_id } }
  let(:holding_ids) { ["221349371140006381"] }
  subject do
    described_class.new(record: offsite, holding_ids: holding_ids)
  end

  context "#combined" do
    it "is an array with one offsite holding" do
      expect(subject.combined.count).to eq(1)
      expect(subject.first.class.name).to match("Offsite")
    end
  end
end
