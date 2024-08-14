require "common/subjects"
RSpec.describe Common::Subject::Normalize do
  context "#normalize as included behavior" do
    before(:each) do
      @input_string = ""
    end
    subject do
      klass.new.normalize(@input_string)
    end
    let(:klass) do
      Class.new { include Common::Subject::Normalize }
    end
    it "replaces tabs with spaces" do
      @input_string = "too\tmany\ttabs"
      expect(subject).to eq("too many tabs")
    end
    it "removes punctuation" do
      @input_string = ".,;"
      expect(subject).to eq("")
    end
    it "keeps parens and quotes and hyphens" do
      @input_string = "(((hello) -- \"\"\" ''' 'world'-"
      expect(subject).to eq(@input_string)
    end
  end
  context "module function" do
    it "responds to .normalize" do
      expect(described_class).to respond_to(:normalize)
    end
  end
end
