require_relative "../spec_helper"
require "jobs"
require "securerandom"
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

####

class TranslationMapGeneratorDouble
  attr_reader :name, :file_path
  def initialize(file_size: 20)
    @name = "name"
    @file_path = "translation_map.yaml"
    @file_size = file_size
  end

  def generate_translation_map
    SecureRandom.random_bytes(@file_size)
  end

  def write_to_file(path)
    File.write(path, generate_translation_map)
  end

  class NoWrite < TranslationMapGeneratorDouble
    def write_to_file(path)
    end
  end
end

RSpec.describe Jobs::TranslationMapGenerator, ".generate" do
  before(:each) do
    @tmp_dir = File.join(S.project_root, "tmp")

    Dir.mkdir(@tmp_dir) unless File.exist?(@tmp_dir)

    @params = {
      generator: TranslationMapGeneratorDouble.new,
      dir: @tmp_dir
    }
  end

  let(:tm_path) { File.join(@tmp_dir, @params[:generator].file_path) }

  after(:each) do
    FileUtils.remove_dir(@tmp_dir, "true")
  end

  subject do
    described_class.generate(**@params)
  end

  context "empty translation map directory" do
    it "generates translation maps" do
      expect(File.exist?(tm_path)).to eq(false)
      subject
      expect(File.exist?(tm_path)).to eq(true)
    end
  end
  context "has new translation map files" do
    it "does not generate new translation maps" do
      `touch #{tm_path}`
      subject
      # This means that the empty touched file hasn't been replaced
      expect(File.size?(tm_path)).to be_nil
    end
  end
  context "force param is true" do
    it "generates a new file" do
      @params[:force] = true
      `touch #{tm_path}`
      subject
      expect(File.size?(tm_path)).to eq(20)
    end
  end
  context "has old translation map files" do
    it "generates new files" do
      `touch -d "-2 days" #{tm_path}`
      subject
      # this means the empty file has been replaced
      expect(File.size?(tm_path)).to eq(20)
    end
  end
  context "fails to write a big enough file" do
    it "errors out for too small lib_loc_info" do
      @params[:generator] = TranslationMapGeneratorDouble.new(file_size: 2)
      expect { subject }.to raise_error(StandardError)
    end
  end
  context "fails to write a file" do
    it "errors out" do
      @params[:generator] = TranslationMapGeneratorDouble::NoWrite.new
      expect { subject }.to raise_error(StandardError)
    end
  end
end
