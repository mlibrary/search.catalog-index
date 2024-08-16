require "traject"
require "traject/macros/common/subject"
RSpec.describe Traject::Macros::Common::Subject do
  let(:record) do
    MARC::XMLReader.new("./spec/fixtures/unauthorized_immigrants.xml").first
  end
  let(:klass) do
    Class.new { extend Traject::Macros::Common::Subject }
  end
  before(:each) do
    @context = OpenStruct.new(
      clipboard: {subject: Common::Subjects.new(record)}
    )
  end
  context "lcsh_subjects" do
    it "gets the lc subjects" do
      accumulator = []
      klass.lcsh_subjects.call(record, accumulator, @context)
      expect(accumulator).to eq(["United States. Personal Responsibility and Work Opportunity Reconciliation Act of 1996",
        "COVID-19 (Disease)",
        "Public welfare--United States"])
    end
  end
  context "non_lcsh_subjects" do
    it "gets the non lc subjects" do
      accumulator = []
      klass.non_lcsh_subjects.call(record, accumulator, @context)
      expect(accumulator).to eq([])
    end
  end
  context "remediated_lcsh_subjects" do
    it "gets the remediated lc subjects" do
      accumulator = []
      klass.remediated_lcsh_subjects.call(record, accumulator, @context)
      expect(accumulator).to eq(["Undocumented immigrants--United States"])
    end
  end
  context "subject_browse_subjects" do
    it "gets the subject_browse subjects" do
      accumulator = []
      klass.subject_browse_subjects.call(record, accumulator, @context)
      expect(accumulator).to contain_exactly(
        "United States. Personal Responsibility and Work Opportunity Reconciliation Act of 1996",
        "COVID-19 (Disease)",
        "Public welfare--United States",
        "Undocumented immigrants--United States"
      )
    end
  end
  context "topics" do
    it "gets the topics" do
      accumulator = []
      klass.topics.call(record, accumulator, @context)
      expect(accumulator).to contain_exactly(
        "United States.",
        "United States. Personal Responsibility and Work Opportunity Reconciliation Act of 1996",
        "COVID-19 (Disease)",
        "Undocumented immigrants",
        "Undocumented immigrants United States.",
        "Public welfare",
        "Public welfare United States.",
        "Aliens",
        "Aliens Legal status, laws, etc. United States.",
        "Illegal aliens",
        "Illegal aliens Legal status, laws, etc. United States.",
        "Undocumented foreign nationals",
        "Undocumented foreign nationals United States.",
        "Illegal aliens United States.",
        "Aliens, Illegal",
        "Aliens, Illegal United States.",
        "Illegal immigrants",
        "Illegal immigrants United States.",
        "Undocumented noncitizens",
        "Undocumented noncitizens United States."
      )
    end
  end
  context "subject_facets" do
    it "gets the subject facets" do
      accumulator = []
      klass.subject_facets.call(record, accumulator, @context)
      expect(accumulator).to contain_exactly(
        "United States.",
        "United States. Personal Responsibility and Work Opportunity Reconciliation Act of 1996",
        "COVID-19 (Disease)",
        "Undocumented immigrants",
        "Undocumented immigrants United States.",
        "Public welfare",
        "Public welfare United States."
      )
    end
  end
end
