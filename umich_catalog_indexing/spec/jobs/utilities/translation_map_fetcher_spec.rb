require_relative "../../spec_helper"
require "jobs"
require "securerandom"

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
end

RSpec.describe Jobs::Utilities::TranslationMapFetcher do
  before(:each) do
    @tmp_dir = File.join(S.project_root, "tmp")
    @umich_dir = File.join(@tmp_dir, "umich")
    @hlb_path = File.join(@tmp_dir, "hlb.json.gz")

    Dir.mkdir(@tmp_dir) unless File.exist?(@tmp_dir)
    Dir.mkdir(@umich_dir) unless File.exist?(@umich_dir)

    @params = {
      high_level_browse_klass: class_double(HighLevelBrowse, fetch_and_save: nil),
      translation_map_generators: [TranslationMapGeneratorDouble.new],
      translation_map_dir: @tmp_dir
    }
  end

  let(:tm_path) { File.join(@tmp_dir, @params[:translation_map_generators][0].file_path) }

  after(:each) do
    FileUtils.remove_dir(@tmp_dir, "true")
  end

  def string_of_size(size)
    SecureRandom.random_bytes(size)
  end

  subject do
    described_class.new(**@params)
  end

  context "#run" do
    context "empty translation map directory" do
      it "generates translation maps" do
        expect(File.exist?(tm_path)).to eq(false)
        subject.run
        expect(File.exist?(tm_path)).to eq(true)
        expect(@params[:high_level_browse_klass]).to have_received(:fetch_and_save)
      end
    end
    context "has new translation map files" do
      it "does not generate new translation maps" do
        `touch #{tm_path}`
        `touch #{@hlb_path}`
        subject.run
        # This means that the empty touched file hasn't been replaced
        expect(File.size?(tm_path)).to be_nil
        expect(@params[:high_level_browse_klass]).not_to have_received(:fetch_and_save)
      end
    end
    context "has old translation map files" do
      it "generates new files" do
        `touch -d "-2 days" #{tm_path}`
        `touch -d "-2 days" #{@hlb_path}`
        subject.run
        # this means the empty file has been replaced
        expect(File.size?(tm_path)).to eq(20)
        expect(@params[:high_level_browse_klass]).to have_received(:fetch_and_save)
      end
    end
    context "fails to write a big enough file" do
      it "errors out for too small lib_loc_info" do
        @params[:translation_map_generators][0] = TranslationMapGeneratorDouble.new(file_size: 2)
        expect { subject.run }.to raise_error(StandardError)
      end
    end
  end
end
