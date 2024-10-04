# frozen_string_literal: true

RSpec.describe HighLevelBrowse do

  let(:hlb) { HighLevelBrowse.fetch }

  it "has a version number" do
    expect(HighLevelBrowse::VERSION).not_to be nil
  end

  it "runs basic sanity checks" do
    expect(hlb['QA1']).to eq([["Science", "Mathematics"]])
    expect(hlb['P11']).to eq [["Humanities", "Linguistics"]]
    expect(hlb['AAA11']).to eq []
  end

  it "can do a basic save/load" do
    dir = Dir.tmpdir
    HighLevelBrowse.fetch_and_save(dir: dir)
    loaded = HighLevelBrowse.load(dir: dir)
    expect(loaded['QA1']).to eq [["Science", "Mathematics"]]
  end

  it "finds a three-level item" do
    expect(hlb["pc1100"]).to include ["Humanities", "Romance Languages and Literatures", "Italian Language and Literatures"]
  end
end
