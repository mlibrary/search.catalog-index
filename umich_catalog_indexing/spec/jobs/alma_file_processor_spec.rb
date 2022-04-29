require_relative '../spec_helper.rb'
require "jobs"
RSpec.describe Jobs::Utilities::AlmaFileProcessor do
  before(:each) do
    @src_path = "search_daily_bibs/file.tar.gz"
  end
  subject do
    described_class.new(path: @src_path, destination: "/app/scratch")
  end
  context "#run" do
    before(:each) do
      @tar_double = double("TarDouble", exec: "")
      @mkdir_double = double("MkidrDouble", mkdir: "")
      @run_params = {
        sftp: instance_double(Jobs::Utilities::SFTP, get: ""),
        tar: lambda{|path, destination| @tar_double.exec(path, destination)},
        mkdir: lambda{|dir| @mkdir_double.mkdir(dir)}
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
    it "calls mkdir with scratch dir" do
      expect(@mkdir_double).to receive(:mkdir).with("/app/scratch")
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
      @dir_delete_double = class_double(FileUtils, remove_dir: nil)
      @delete = lambda{|file| @dir_delete_double.remove_dir(file)}
    end
    it "removes the files put in the scratch directory" do
      expect(@dir_delete_double).to receive(:remove_dir).with("/app/scratch")
      subject.clean(@delete) 
    end
  end
end
