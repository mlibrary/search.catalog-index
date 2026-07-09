require_relative "../spec_helper"
require "indexer"
RSpec.describe Indexer::IndexUpdate do
  let(:solr_url) { "http://solr" }
  context ".alma" do
    before(:each) do
      @files =
        [
          "/some_directory/file1_20220101_delete.tar.gz",
          "/some_directory/file2_20220101_delete_1.tar.gz",
          "/some_directory/file3_20220101_delete_15.tar.gz",
          "/some_directory/file1_20220101_new.tar.gz",
          "/some_directory/file2_20220101_new_1.tar.gz",
          "/some_directory/file3_20220101_new_15.tar.gz",
          "/some_directory/file1_different_date_20220102_new.tar.gz",
          "/some_directory/file1_different_date_20220102_delete.tar.gz",
          "/some_directory/new_delete_file2_invalid.tar.gz"
        ]

      @params = {
        date: Date.parse("20220101"),
        solrs: [solr_url],
        environment: "production"
      }
      allow(IndexIt).to receive(:perform_async)
      allow(DeleteIt).to receive(:perform_async)
      allow(IndexIt).to receive(:set).and_return(IndexIt)
      allow(DeleteIt).to receive(:set).and_return(DeleteIt)
    end
    subject do
      allow(S).to receive(:alma_update_file_paths).and_return(@files)
      described_class.alma(**@params)
    end
    it "calls IndexIt with appropriate files and solr" do
      expect(IndexIt).to receive(:perform_async).with("/some_directory/file1_20220101_new.tar.gz", solr_url)
      expect(IndexIt).to receive(:perform_async).with("/some_directory/file2_20220101_new_1.tar.gz", solr_url)
      expect(IndexIt).to receive(:perform_async).with("/some_directory/file3_20220101_new_15.tar.gz", solr_url)
      expect(IndexIt).to receive(:set).with({queue: "default"})
      subject
    end
    it "calls DeleteIt with appropriate files and solr" do
      expect(DeleteIt).to receive(:perform_async).with("/some_directory/file1_20220101_delete.tar.gz", solr_url)
      expect(DeleteIt).to receive(:perform_async).with("/some_directory/file2_20220101_delete_1.tar.gz", solr_url)
      expect(DeleteIt).to receive(:perform_async).with("/some_directory/file3_20220101_delete_15.tar.gz", solr_url)
      expect(DeleteIt).to receive(:set).with({queue: "default"})
      subject
    end
    it "does not call IndexIt when no new files" do
      @files[3] = "not_new_anymore"
      @files[4] = "not_new_anymore"
      @files[5] = "not_new_anymore"
      expect(IndexIt).not_to receive(:perform_async)
      subject
    end
    it "does not call DeleteIt when no new files" do
      @files[0] = "not_delete_anymore"
      @files[1] = "not_delete_anymore"
      @files[2] = "not_delete_anymore"
      expect(DeleteIt).not_to receive(:perform_async)
      subject
    end
  end
  context ".zephir" do
    before(:each) do
      @files = [
        "/some_directory/zephir_upd_20240601_00.json.gz",
        "/some_directory/zephir_upd_20240601_01.json.gz"
      ]
      @params = {
        date: Date.parse("20240602"),
        solrs: ["http://solr"],
        environment: "production"
      }
      allow(IndexJson).to receive(:perform_async)
      allow(IndexJson).to receive(:set).and_return(IndexJson)
      @client = double("client", ls: @files)
      allow(SFTP).to receive(:client).and_return(@client)
    end
    subject do
      described_class.zephir(**@params)
    end
    context "#run" do
      it "calls IndexJson and asks for yesterdays update" do
        expect(IndexJson).to receive(:perform_async).with("/some_directory/zephir_upd_20240601_00.json.gz", solr_url)
        expect(IndexJson).to receive(:perform_async).with("/some_directory/zephir_upd_20240601_01.json.gz", solr_url)
        expect(@client).to receive(:ls).with(/.*zephir_upd_20240601.*/)
        subject
      end
    end
  end
end
