require "traject"
describe "umich_alma" do
  def get_record(path)
    reader = MARC::XMLReader.new(path)
    for r in reader
      return r
    end
  end
  let(:hurdy_gurdy) do
    get_record("./spec/fixtures/hurdy_gurdy.xml")
  end
  let(:arborist) do
    get_record("./spec/fixtures/arborist.xml")
  end
  let(:indexer) do
    Traject::Indexer.new do
      load_config_file("./spec/support/traject_settings.rb")
      load_config_file("./indexers/umich_alma.rb")
    end
  end
  let(:expected_arborist) do
    [
      {
        "library" => "ELEC",
        "link" =>
          "https://na04.alma.exlibrisgroup.com/view/uresolver/01UMICH_INST/openurl-UMAA?u.ignore_date_coverage=true&portfolio_pid=531031051570006381&Force_direct=true",
        "link_text" => "Available online",
        "link_campus" => "ann_arbor",
        "interface_name" => "archived issues via the International Society of Arboriculture",
        "public_note" => "Access to archived issues via the International Society of Arboriculture online version:",
        "note" => "archived issues via the International Society of Arboriculture. Access to archived issues via the International Society of Arboriculture online version.",
        "status" => "Available",

        "finding_aid" => false,
        "authentication_note" => [],
        "collection_name" => nil
      },
      {
        "finding_aid" => false,
        "interface_name" => "International Society of Arboriculture",
        "library" => "ELEC",
        "link" =>
        "https://na04.alma.exlibrisgroup.com/view/uresolver/01UMICH_INST/openurl-UMAA?u.ignore_date_coverage=true&portfolio_pid=531031051590006381&Force_direct=true",
        "link_text" => "Available online",
        "link_campus" => "ann_arbor",
        "public_note" =>
        "Institutional password required for access to the International Society of Arboriculture online version; authentication required:",
        "note" =>
        "International Society of Arboriculture. Institutional password required for access to the International Society of Arboriculture online version; authentication required.",
        "status" => "Available",
        "authentication_note" => [],
        "collection_name" => nil
      },
      {
        "callnumber" => "SB 435 .A71",
        "display_name" => "Shapiro Science Oversize Stacks - 4th floor",
        "floor_location" => "",
        "hol_mmsid" => "22767949280006381",
        "info_link" => "http://lib.umich.edu/locations-and-hours/shapiro-library",
        "items" =>
        [
          {
            "barcode" => "A30842",
            "callnumber" => "SB 435 .A71",
            "can_reserve" => false,
            "description" => "v.30:no.4(2021:Aug.)",
            "display_name" => "Shapiro Science Oversize Stacks - 4th floor",
            "fulfillment_unit" => "General",
            "location_type" => "OPEN",
            "info_link" => "http://lib.umich.edu/locations-and-hours/shapiro-library",
            "inventory_number" => nil,
            "item_id" => "231173897050006381",
            "item_policy" => nil,
            "library" => "SHAP",
            "location" => "SOVR",
            "material_type" => "ISSUE",
            "permanent_library" => "SHAP",
            "permanent_location" => "SOVR",
            "process_type" => "ACQ",
            "public_note" => nil,
            "record_has_finding_aid" => false,
            "temp_location" => false
          },
          {
            "barcode" => "A113546",
            "callnumber" => "SB 435 .A71",
            "can_reserve" => false,
            "description" => "v.31:no.2(2022:Apr.)",
            "display_name" => "Shapiro Science Oversize Stacks - 4th floor",
            "fulfillment_unit" => "General",
            "location_type" => "OPEN",
            "info_link" => "http://lib.umich.edu/locations-and-hours/shapiro-library",
            "inventory_number" => nil,
            "item_id" => "231228590060006381",
            "item_policy" => "08",
            "library" => "SHAP",
            "location" => "SOVR",
            "material_type" => "ISSUE",
            "permanent_library" => "SHAP",
            "permanent_location" => "SOVR",
            "process_type" => nil,
            "public_note" => nil,
            "record_has_finding_aid" => false,
            "temp_location" => false
          }
        ],
        "library" => "SHAP",
        "location" => "SOVR",
        "public_note" => "CURRENT ISSUES IN SERIAL SERVICES, 203 NORTH HATCHER",
        "record_has_finding_aid" => false,
        "summary_holdings" => "2- : 1993-"
      }
    ]
  end
  let(:expected_hurdy_gurdy) do
    [{"callnumber" => "ML760 .P18",
      "display_name" => "Music",
      "floor_location" => "",
      "hol_mmsid" => "22744541740006381",
      "info_link" => "http://lib.umich.edu/locations-and-hours/music-library",
      "items" =>
          [
            {"barcode" => "39015009714562",
             "callnumber" => "ML760 .P18",
             "can_reserve" => false,
             "description" => nil,
             "display_name" => "Music",
             "fulfillment_unit" => "General",
             "location_type" => "OPEN",
             "info_link" => "http://lib.umich.edu/locations-and-hours/music-library",
             "inventory_number" => nil,
             "item_id" => "23744541730006381",
             "item_policy" => "01",
             "library" => "MUSIC",
             "location" => "NONE",
             "material_type" => "BOOK",
             "permanent_library" => "MUSIC",
             "permanent_location" => "NONE",
             "process_type" => nil,
             "public_note" => nil,
             "record_has_finding_aid" => false,
             "temp_location" => false}
          ],
      "library" => "MUSIC",
      "location" => "NONE",
      "public_note" => nil,
      "record_has_finding_aid" => false,
      "summary_holdings" => nil}]
  end
  before(:each) do
    @record = nil
  end
  subject do
    indexer.process_record(@record).output_hash
  end
  it "has expected physical hol" do
    @record = hurdy_gurdy
    # item_policy = @record["974"].subfields.find{|s| s.code == "p" }
    # item_policy.value = "08"
    hol = JSON.parse(subject["hol"].first)
    expect(hol).to eq(expected_hurdy_gurdy)
  end
  it "has expected elec hol" do
    @record = arborist
    hol = JSON.parse(subject["hol"].first)
    expect(hol).to eq(expected_arborist)
  end
end
