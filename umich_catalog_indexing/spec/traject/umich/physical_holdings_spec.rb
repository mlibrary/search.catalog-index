require "traject"
require "umich_traject"
describe Traject::UMich::PhysicalHoldings do
  let(:offsite) do
    get_record("./spec/fixtures/hsrs_one_item.xml")
  end
  let(:non_offsite_id) { "12345" }
  let(:non_offsite_holding_data) do
    MARC::DataField.new("852", "0", " ",
      ["b", "HATCH"], ["a", "MIU"],
      ["c", "GRAD"], ["8", non_offsite_id])
  end
  let(:non_offsite_item) {
    MARC::DataField.new("974", "0", " ",
      ["8", non_offsite_id],
      ["b", "HATCH :"], ["a", "MIU"],
      ["c", "GRAD"])
  }
  let(:extra_offsite_id) { "78910" }
  let(:extra_offsite_holding_data) do
    MARC::DataField.new("852", "0", " ",
      ["b", "OFFS"], ["a", "MIU"],
      ["c", "MAIN"], ["8", extra_offsite_id])
  end
  let(:extra_offsite_item) {
    MARC::DataField.new("974", "0", " ",
      ["8", extra_offsite_id],
      ["b", "OFFS"], ["a", "MIU"],
      ["c", "MAIN"])
  }

  let(:holding_ids) { ["221349371140006381"] }
  subject do
    described_class.new(record: offsite, holding_ids: holding_ids)
  end

  context "#combined" do
    it "is an array with one offsite holding" do
      expect(subject.combined.count).to eq(1)
      expect(subject.first.class.name).to match("Offsite")
    end

    it "has two holdings when there is an offsite and a non offsite holding" do
      holding_ids.push(non_offsite_id)
      offsite.append(non_offsite_holding_data)
      offsite.append(non_offsite_item)
      expect(subject.combined.count).to eq(2)
    end

    it "has one holding when there are multiple offsite holdings" do
      holding_ids.push(extra_offsite_id)
      offsite.append(extra_offsite_holding_data)
      offsite.append(extra_offsite_item)
      expect(subject.combined.count).to eq(1)
    end
  end
end
