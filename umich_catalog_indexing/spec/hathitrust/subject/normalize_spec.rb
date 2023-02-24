require 'hathitrust/subject.rb'
RSpec.describe HathiTrust::Subject::Normalize do
  context ".normalize" do
    before(:each) do
      @input_string = ""
    end
    subject do
      described_class.normalize(@input_string)
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
  context "included normalize" do
    before(:each) do
      @input_string = ""
    end
    subject do
      klass.new.test_normalize(@input_string)
    end
    let(:klass) do
      Class.new do
        include HathiTrust::Subject::Normalize
        def test_normalize(str)
          normalize(str)
        end
      end
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
end
