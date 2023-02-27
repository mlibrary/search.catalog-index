require "traject"
describe "subject_topic" do
  let(:base_record) do
    reader = MARC::XMLReader.new('./spec/fixtures/hurdy_gurdy.xml')
    for r in reader
      return r
    end
  end
  let(:indexer) do
    Traject::Indexer.new do
      load_config_file("./spec/support/traject_settings.rb")
      load_config_file("./indexers/umich_alma.rb")
    end
  end
  before(:each) do
    @record = base_record
    @expected_output = 
    [{"callnumber"=>"ML760 .P18",
         "display_name"=>"Music",
         "floor_location"=>"",
         "hol_mmsid"=>"22744541740006381",
         "info_link"=>"http://lib.umich.edu/locations-and-hours/music-library",
         "items"=>
          [{"barcode"=>"39015009714562",
            "callnumber"=>"ML760 .P18",
            "can_reserve"=>false,
            "description"=>nil,
            "display_name"=>"Music",
            "fulfillment_unit"=>"General",
            "info_link"=>"http://lib.umich.edu/locations-and-hours/music-library",
            "inventory_number"=>nil,
            "item_id"=>"23744541730006381",
            "item_policy"=>"01",
            "library"=>"MUSIC",
            "location"=>"NONE",
            "permanent_library"=>"MUSIC",
            "permanent_location"=>"NONE",
            "process_type"=>nil,
            "public_note"=>nil,
            "record_has_finding_aid"=>false,
            "temp_location"=>false}],
         "library"=>"MUSIC",
         "location"=>"NONE",
         "public_note"=>nil,
         "record_has_finding_aid"=>false,
         "summary_holdings"=>nil}
    ]
  end
  subject do
    indexer.process_record(@record).output_hash
  end
  it "has expected hol" do
    item_policy = @record["974"].subfields.find{|s| s.code == "p" }
    item_policy.value = "08"
    hol = JSON.parse(subject["hol"].first)
    expect(hol).to eq(@expected_output)
  end
end
