require_relative "spec_helper"
require "index_zephir_for_date"
RSpec.describe IndexZephirForDate do
  before(:each) do
    @params = {
      date: "20240601",
      file_paths: [
        "/some_directory/zephir_upd_20240531_00.json.gz",
        "/some_directory/zephir_upd_20240531_01.json.gz",
        "/some_directory/zephir_upd_20240601_00.json.gz",
        "/some_directory/zephir_upd_20240601_01.json.gz",
        "/some_directory/zephir_upd_20240602_00.json.gz"
      ],
      solr_url: "http://solr",
      index_json: instance_double(IndexJson, perform: nil)
    }
  end
  subject do
    described_class.new(**@params)
  end
  context "initialize" do
    it "raises an error when date is in the wrong format" do
      @params[:date] = "not a date string"
      expect { subject }.to raise_error(ArgumentError, "invalid date")
    end
    it "raises an error when file_paths is not an array of strings" do
      @params[:file_paths] = "not an array of strings"
      expect { subject }.to raise_error(StandardError, /file_paths must be an array of file path strings/)
    end

    it "raises an error if solr_url is not a string" do
      @params[:solr_url] = []
      expect { subject }.to raise_error(StandardError, "solr_url must be a string of the solr to index into")
    end
  end
  context "#run" do
    it "calls IndexJson with appropriate files and solr" do
      expect(@params[:index_json]).to receive(:perform).with("/some_directory/zephir_upd_20240601_00.json.gz", @params[:solr_url])
      expect(@params[:index_json]).to receive(:perform).with("/some_directory/zephir_upd_20240601_01.json.gz", @params[:solr_url])
      subject.run
    end
    it "does not call IndexJson when no files for date" do
      @params[:date] = "20240701"
      expect(@params[:index_json]).not_to receive(:perform)
      subject.run
    end
  end
end
