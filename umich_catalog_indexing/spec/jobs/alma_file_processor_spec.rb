require_relative '../spec_helper.rb'
require "jobs"
RSpec.describe Jobs::Utilities::AlmaFileProcessor do
  before(:each) do
    @src_path = "search_daily_bibs/file.tar.gz"
  end
  subject do
    described_class.new(path: @src_path)
  end
  context "#run" do
    before(:each) do
      @tar_double = double("TarDouble", exec: "")
      @run_params = {
        sftp: instance_double(Jobs::Utilities::SFTP, get: ""),
        tar: lambda{|path, destination| @tar_double.exec(path, destination)}
      }
    end
    it "calls sftp get function with path and destination" do
      expect(@run_params[:sftp]).to receive(:get).with(@src_path, "/app/scratch")
      subject.run(**@run_params)
    end
    it "calls tar on the with the appropriate parms" do
      expect(@tar_double).to receive(:exec).with("/app/scratch/file.tar.gz", "/app/scratch")
      subject.run(**@run_params)
    end
  end 
  context "#xml_file" do
    it "returns the appropriate filename" do
      expect(subject.xml_file).to eq("/app/scratch/file.xml")
    end
  end
  context "#clean" do
    before(:each) do
      @file_delete_double = class_double(File, delete: nil)
      @delete = lambda{|file| @file_delete_double.delete(file)}
    end
    it "removes the files put in the scratch directory" do
      expect(@file_delete_double).to receive(:delete).with("/app/scratch/file.tar.gz")
      expect(@file_delete_double).to receive(:delete).with("/app/scratch/file.xml")
      subject.clean(@delete) 
    end
  end
end
