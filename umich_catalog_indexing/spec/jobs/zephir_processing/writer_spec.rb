describe Jobs::ZephirProcessing::Writer do
  before(:each) do
    @scratch_dir = File.join(S.project_root, "scratch", "writer")
    FileUtils.mkdir(@scratch_dir)
    @params = {
      scratch_dir: @scratch_dir,
      prefix: "my_prefix",
      batch_size: 3
    }
  end

  subject do
    described_class.new(**@params)
  end

  context "first line of file" do
    it "writes the line to my_prefix_01.gz and closes it when told" do
      s = subject
      s.write("line")
      expect(s.io.closed?).to eq(false)
      s.close
      expect(s.io.closed?).to eq(true)
      output_file = File.join(@scratch_dir, "my_prefix_00.json.gz")
      expect(`zcat #{output_file}`).to eq("line\n")
    end
  end
  context "at batch break" do
    it "writes the line to the next file and closes it when told" do
      s = subject
      s.write("line")
      s.write("line")
      s.write("line")
      output_file = File.join(@scratch_dir, "my_prefix_00.json.gz")
      expect(`zcat #{output_file}`).to eq("line\nline\nline\n")
      s.write("line")
      expect(s.io.closed?).to eq(false)
      s.close
      expect(s.io.closed?).to eq(true)
      output_file2 = File.join(@scratch_dir, "my_prefix_01.json.gz")
      expect(`zcat #{output_file2}`).to eq("line\n")
    end
  end

  after(:each) do
    FileUtils.remove_dir(@scratch_dir)
  end
end
