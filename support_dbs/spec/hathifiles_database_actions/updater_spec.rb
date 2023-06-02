RSpec.describe HathifilesDatabaseActions::Updater do
  before(:each) do
    @logger = instance_double(Logger, info: nil, error: nil)
    @connection = instance_double(HathifilesDatabase::DB::Connection, update_from_file: nil)
  end
  subject do
    described_class.new(date: "2023-05-02", logger: @logger, connection: @connection)
  end
  it "has daily hathifile name" do
    expect(subject.hathifile).to eq("hathi_upd_20230502.txt.gz")
  end
  it "runs update_from_file command" do
    stub_request(:get, "#{ENV.fetch("HT_HOST")}/files/hathifiles/hathi_upd_20230502.txt.gz").
      to_return(status: 200, body: File.new("./spec/fixtures/hathi_update.txt.gz"))
    expect(@connection).to receive(:update_from_file)
    subject.run
  end
  it "empties the scratch directory even if there's an error" do
    stub_request(:get, "#{ENV.fetch("HT_HOST")}/files/hathifiles/hathi_upd_20230502.txt.gz").
      to_timeout
    expect(@connection).not_to receive(:update_from_file)
    subject.run
    expect(Pathname.new(subject.scratch_dir)).not_to exist
  end
end
