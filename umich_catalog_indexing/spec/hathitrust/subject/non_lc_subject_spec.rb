require 'hathitrust/subject.rb'
require 'marc'
RSpec.describe HathiTrust::Subject::NonLCSubject do
  let(:non_lc_subject_field) do
    MARC::DataField.new( "650", "", "7", 
      ["a", "a"], 
      ["b", "b"], 
      ["c", "c"]
    )
  end
  subject do
    HathiTrust::Subject.new(non_lc_subject_field)
  end
  
  context "lc_subject_field?" do
    it "is false" do
      expect(subject.lc_subject_field?).to eq(false)
    end
  end

  context "subject_string" do
    it "acts like an LCSubjectHierarchical" do
      expect(subject.subject_string).to eq("a--b--c")
    end
  end
end
