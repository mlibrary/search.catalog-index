describe "post /v1/jobs/", type: :request do
  context "correct request" do
    it "creates a job with a started status" do
      post "/v1/jobs", params: {job_id: "12345", params: "params", job_class: "JobClass"}
      j = Job.last
      expect(j.job_id).to eq("12345")
      expect(j.params).to eq("params")
      expect(j.job_class).to eq("JobClass")
      expect(j.status).to eq("started")
    end
  end
end
