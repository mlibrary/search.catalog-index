require "umich_traject/enumcron_sorter"
require "umich_traject/physical_item"
RSpec.describe Traject::UMich::EnumcronSorter do
  it "sorts enumcrons?" do
    array = [ 
      instance_double(Traject::UMich::PhysicalItem, description: "v.31:no.2(2022:Apr.)"),
      instance_double(Traject::UMich::PhysicalItem, description: "v.30:no.4(2021:Aug.)"),
      instance_double(Traject::UMich::PhysicalItem, description: nil) 
    ]
    expected_array = [ 
      nil, 
      "v.30:no.4(2021:Aug.)", 
      "v.31:no.2(2022:Apr.)"
    ]
    expect(described_class.sort(array).map{|x| x.description}).to eq(expected_array)
  end
end
