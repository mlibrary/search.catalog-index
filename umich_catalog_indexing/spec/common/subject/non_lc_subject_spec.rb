require "common/subjects"
require "marc"
RSpec.describe Common::Subject::NonLCSubject do
  let(:non_lc_subject_field) do
    MARC::DataField.new("650", "", "7",
      ["a", "a"],
      ["b", "b"],
      ["c", "c"])
  end
  subject do
    Common::Subject.new(non_lc_subject_field)
  end

  context "lc_subject_field?" do
    it "is false" do
      expect(subject.lc_subject_field?).to eq(false)
    end
  end
end
