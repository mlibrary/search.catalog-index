describe JobManager do
  context ".uncompleted_jobs" do
    it "shows uncompleted jobs" do
      create(:started_job, job_id: "started" )
      create(:completed_job, job_id: "completed")
      list = described_class.uncompleted_jobs
      expect(list.count).to eq(1)
      expect(list.first.job_id).to eq("started")
    end
    
    it "shows uncompeted jobs where arguments match the given string" do
      create(:started_job, job_id: "started_1", arguments: "aa1zz" )
      create(:started_job, job_id: "started_2", arguments: "aa2zz" )
      list = described_class.uncompleted_jobs("1")
      expect(list.count).to eq(1)
      expect(list.first.job_id).to eq("started_1")
    end
  end
  context ".completed_jobs" do
    it "shows completed jobs" do
      create(:started_job, job_id: "started" )
      create(:completed_job, job_id: "completed")
      list = described_class.completed_jobs
      expect(list.count).to eq(1)
      expect(list.first.job_id).to eq("completed")
    end
    
    it "shows competed jobs where arguments match the given string" do
      create(:completed_job, job_id: "completed_1", arguments: "aa1zz" )
      create(:completed_job, job_id: "completed_2", arguments: "aa2zz" )
      list = described_class.completed_jobs("1")
      expect(list.count).to eq(1)
      expect(list.first.job_id).to eq("completed_1")
    end
  end
  context ".jobs" do
    it "lists all jobs" do
      create(:started_job, job_id: "started" )
      create(:completed_job, job_id: "completed")
      list = described_class.jobs
      expect(list.count).to eq(2)
      expect(list.first.job_id).to eq("started")
      expect(list.second.job_id).to eq("completed")
    end
    it "lists all jobs for a given string" do
      create(:started_job, job_id: "started", arguments: "aa1zz" )
      create(:completed_job, job_id: "completed", arguments: "aa1zz" )
      create(:completed_job, job_id: "completed2", arguments: "aa2zz" )
      list = described_class.jobs("1")
      expect(list.count).to eq(2)
      expect(list.first.job_id).to eq("started")
      expect(list.second.job_id).to eq("completed")
    end
  end
  context ".restart_uncompleted_jobs" do
    before(:each) do
      @sidekiq_client = class_double(Sidekiq::Client, push_bulk: nil)
      @logger = instance_double(Logger, info: nil)
    end
    it "restarts all uncompleted_jobs and deletes the old jobs" do
      j = create(:started_job, job_id: "started", arguments: ["aa1zz"].to_json )
      j2 = create(:started_job, job_id: "started2", arguments: ["aa1zz2"].to_json )
      create(:completed_job, job_id: "completed", arguments: ["aa1zz"].to_json )
      expect(Job.all.count).to eq(3)
      expect(Status.all.count).to eq(3)
      expect(@sidekiq_client).to receive(:push_bulk).exactly(2).times
      described_class.restart_uncompleted_jobs(nil, @sidekiq_client, @logger) 
      expect(Job.all.count).to eq(1)
      expect(Status.all.count).to eq(1)
    end
    it "restarts all uncompleted_jobs that match the given string and deletes the old jobs" do
      j = create(:started_job, job_id: "started", arguments: ["aa1zz"].to_json )
      j2 = create(:started_job, job_id: "started2", arguments: ["aa2zz"].to_json )
      create(:completed_job, job_id: "completed", arguments: ["aa1zz"].to_json )
      expect(Job.all.count).to eq(3)
      expect(Status.all.count).to eq(3)
      expect(@sidekiq_client).to receive(:push_bulk).exactly(1).times
      described_class.restart_uncompleted_jobs("1", @sidekiq_client, @logger) 
      expect(Job.all.count).to eq(2)
      expect(Status.all.count).to eq(2)
    end
  end

end
