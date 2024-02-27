require_relative "../../spec_helper"
require "jobs"
require "securerandom"

RSpec.describe Jobs::Utilities::TranslationMapFetcher do
  before(:each) do
    @tmp_dir = File.join(S.project_root, "tmp")
    @umich_dir = File.join(@tmp_dir, "umich")
    @hlb_path = File.join(@tmp_dir, "hlb.json.gz")
    @lib_loc_info_path = File.join(@umich_dir, "libLocInfo.yaml")
    @electronic_collections_path = File.join(@umich_dir, "electronic_collections.yaml")
    Dir.mkdir(@tmp_dir) unless File.exist?(@tmp_dir)
    Dir.mkdir(@umich_dir) unless File.exist?(@umich_dir)
    @params = {
      lib_loc_info_klass: class_double(Jobs::LibLocInfo, generate_translation_map: string_of_size(20)),
      electronic_collections_klass: class_double(Jobs::ElectronicCollections, generate_translation_map: string_of_size(20)),
      high_level_browse_klass: class_double(HighLevelBrowse, fetch_and_save: nil),
      translation_map_dir: @tmp_dir
    }
  end
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
        expect(File.exist?(@lib_loc_info_path)).to eq(false)
        expect(File.exist?(@electronic_collections_path)).to eq(false)
        subject.run
        expect(File.exist?(@lib_loc_info_path)).to eq(true)
        expect(File.exist?(@electronic_collections_path)).to eq(true)
        expect(@params[:high_level_browse_klass]).to have_received(:fetch_and_save)
      end
    end
    context "has new translation map files" do
      it "does not generate new translation maps" do
        `touch #{@lib_loc_info_path}`
        `touch #{@electronic_collections_path}`
        `touch #{@hlb_path}`
        subject.run
        expect(@params[:high_level_browse_klass]).not_to have_received(:fetch_and_save)
        expect(@params[:lib_loc_info_klass]).not_to have_received(:generate_translation_map)
        expect(@params[:electronic_collections_klass]).not_to have_received(:generate_translation_map)
      end
    end
    context "has old translation map files" do
      it "generates new files" do
        `touch -d "-2 days" #{@lib_loc_info_path} `
        `touch -d "-2 days" #{@electronic_collections_path}`
        `touch -d "-2 days" #{@hlb_path}`
        subject.run
        expect(@params[:high_level_browse_klass]).to have_received(:fetch_and_save)
        # expect(@params[:lib_loc_info_klass]).to have_received(:generate_translation_map)
        expect(@params[:electronic_collections_klass]).to have_received(:generate_translation_map)
      end
    end
    context "fails to generate big enough files" do
      it "errors out for too small lib_loc_info" do
        allow(@params[:lib_loc_info_klass]).to receive(:generate_translation_map).and_return(string_of_size(2))
        expect { subject.run }.to raise_error(StandardError)
      end
      it "errors out for too small electronic_collections_file" do
        allow(@params[:electronic_collections_klass]).to receive(:generate_translation_map).and_return(string_of_size(2))
        expect { subject.run }.to raise_error(StandardError)
      end
    end
  end
end
