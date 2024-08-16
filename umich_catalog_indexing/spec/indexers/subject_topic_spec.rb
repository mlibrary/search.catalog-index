require "traject"
describe "subject_topic" do
  let(:record) do
    MARC::XMLReader.new("./spec/fixtures/unauthorized_immigrants.xml").first
  end
  let(:indexer) do
    Traject::Indexer.new do
      load_config_file("./spec/support/traject_settings.rb")
      load_config_file("./indexers/subject_topic.rb")
    end
  end
  subject do
    indexer.process_record(record).output_hash
  end
  it "has expected topic" do
    expect(subject["topic"]).to contain_exactly(
      "United States",
      "United States. Personal Responsibility and Work Opportunity Reconciliation Act of 1996",
      "COVID-19 (Disease)",
      "Undocumented immigrants",
      "Undocumented immigrants United States",
      "Public welfare",
      "Public welfare United States",
      "Aliens",
      "Aliens Legal status, laws, etc. United States",
      "Illegal aliens",
      "Illegal aliens Legal status, laws, etc. United States",
      "Undocumented foreign nationals",
      "Undocumented foreign nationals United States",
      "Illegal aliens United States",
      "Aliens, Illegal",
      "Aliens, Illegal United States",
      "Illegal immigrants",
      "Illegal immigrants United States",
      "Undocumented noncitizens",
      "Undocumented noncitizens United States"
    )
  end

  it "has the expected topicStr" do
    expect(subject["topicStr"]).to contain_exactly(
      "United States",
      "United States. Personal Responsibility and Work Opportunity Reconciliation Act of 1996",
      "COVID-19 (Disease)",
      "Undocumented immigrants",
      "Undocumented immigrants United States",
      "Public welfare",
      "Public welfare United States"
    )
  end

  it "has the expected  lc_subject_display" do
    expect(subject["lc_subject_display"]).to contain_exactly(
      "United States. Personal Responsibility and Work Opportunity Reconciliation Act of 1996",
      "COVID-19 (Disease)",
      "Public welfare -- United States"
    )
  end

  it "has the expected remediated_lc_subject_display" do
    expect(subject["remediated_lc_subject_display"]).to contain_exactly("Undocumented immigrants -- United States")
  end

  it "has the expected non_lc_subject_display" do
    expect(subject["non_lc_subject_display"]).to eq(nil)
  end

  it "has the expected  subject_browse_terms" do
    expect(subject["subject_browse_terms"]).to contain_exactly(
      "United States. Personal Responsibility and Work Opportunity Reconciliation Act of 1996",
      "COVID-19 (Disease)",
      "Public welfare--United States",
      "Undocumented immigrants--United States"
    )
  end
end
