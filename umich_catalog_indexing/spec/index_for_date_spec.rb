require_relative './spec_helper.rb'
require 'index_for_date.rb'
RSpec.describe IndexForDate  do 
  before(:each) do 
    @params = {
      date: "20220101",
      alma_files: [
        "/some_directory/file1_20220101_delete.tar.gz",
        "/some_directory/file2_20220101_delete_1.tar.gz",
        "/some_directory/file3_20220101_delete_15.tar.gz",
        "/some_directory/file1_20220101_new.tar.gz",
        "/some_directory/file2_20220101_new_1.tar.gz",
        "/some_directory/file3_20220101_new_15.tar.gz",
        "/some_directory/file1_different_date_20220102_new.tar.gz",
        "/some_directory/file1_different_date_20220102_delete.tar.gz",
        "/some_directory/new_delete_file2_invalid.tar.gz",
      ],
      solr_url: "http://solr",
      index_it: instance_double(IndexIt, perform: nil),
      delete_it: instance_double(DeleteIt, perform: nil),
      index_hathi: instance_double(IndexHathi, perform: nil),
      logger: instance_double(Logger, info: nil)
    }
  end
  subject do
    described_class.new(**@params)
  end
  context "initialize" do
    it "raises an error when date is in the wrong format" do
      @params[:date] = "not a date string"
      expect{ subject }.to raise_error(ArgumentError, "invalid date")
    end
    it "raises an error when alma files are not an array of strings" do
      @params[:alma_files] = "not an array of strings"
      expect{ subject }.to raise_error(StandardError, "alma_files must be an array of file path strings")
    end
    it "raises an error if solr_url is not a string" do
      @params[:solr_url] = []
      expect{ subject }.to raise_error(StandardError, "solr_url must be a string of the solr to index into")
    end
  end
  context "#run" do
    it "calls IndexIt with appropriate files and solr" do
      expect(@params[:index_it]).to receive(:perform).with("/some_directory/file1_20220101_new.tar.gz", @params[:solr_url])
      expect(@params[:index_it]).to receive(:perform).with("/some_directory/file2_20220101_new_1.tar.gz", @params[:solr_url])
      expect(@params[:index_it]).to receive(:perform).with("/some_directory/file3_20220101_new_15.tar.gz", @params[:solr_url])
      subject.run
    end
    it "calls DeleteIt with appropriate files and solr" do
      expect(@params[:delete_it]).to receive(:perform).with("/some_directory/file1_20220101_delete.tar.gz", @params[:solr_url])
      expect(@params[:delete_it]).to receive(:perform).with("/some_directory/file2_20220101_delete_1.tar.gz", @params[:solr_url])
      expect(@params[:delete_it]).to receive(:perform).with("/some_directory/file3_20220101_delete_15.tar.gz", @params[:solr_url])
      subject.run
    end
    it "calls IndexHathi with appropriate files and solr" do
      expect(@params[:index_hathi]).to receive(:perform).with("zephir_upd_20211231.json.gz", @params[:solr_url])
      subject.run
    end
    it "does not call IndexIt when no new files" do
      @params[:alma_files][3] = "not_new_anymore"
      @params[:alma_files][4] = "not_new_anymore"
      @params[:alma_files][5] = "not_new_anymore"
      expect(@params[:index_it]).not_to receive(:perform)
      subject.run
    end
    it "does not call DeleteIt when no new files" do
      @params[:alma_files][0] = "not_delete_anymore"
      @params[:alma_files][1] = "not_delete_anymore"
      @params[:alma_files][2] = "not_delete_anymore"
      expect(@params[:delete_it]).not_to receive(:perform)
      subject.run
    end
  end
end
