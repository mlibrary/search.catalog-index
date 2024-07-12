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
      clipboard: {subject: Common::Subject.new(record)}
    )
  end
  context "lcsh_subjects" do
    it "gets the lc subjects" do
      accumulator = []
      klass.lcsh_subjects.call(record, accumulator, @context)
      expect(accumulator).to eq(["United States. Personal Responsibility and Work Opportunity Reconciliation Act of 1996",
        "COVID-19 (Disease)",
        "Public welfare -- United States"])
    end
  end
  context "remediated_lcsh_subject" do
    it "gets the non lc subjects" do
      accumulator = []
      klass.remediated_lcsh_subjects.call(record, accumulator, @context)
      expect(accumulator).to eq(["Undocumented immigrants -- United States"])
    end
  end
  context "non_lcsh_subject" do
    it "gets the non lc subjects" do
      accumulator = []
      klass.non_lcsh_subjects.call(record, accumulator, @context)
      expect(accumulator).to eq([])
    end
  end
end
