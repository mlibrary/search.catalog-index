require_relative "../spec_helper"
require "jobs"
Jobs::TranslationMapGenerator.all.each do |klass|
  describe klass do
    it "has a name method" do
      expect(klass.name.class).to eq(String)
    end

    it "has a file_path method" do
      expect(klass.file_path.class).to eq(String)
    end

    it "has a write_to_file method" do
      expect(klass).to respond_to(:write_to_file)
    end

    it "has a generate method" do
      expect(klass).to respond_to(:generate)
    end
  end
end
