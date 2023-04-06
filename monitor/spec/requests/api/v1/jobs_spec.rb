require 'rails_helper'

RSpec.describe "Api::V1::Jobs", type: :request do
  describe "POST /" do
    it "returns http success" do
      post "/api/v1/jobs", params: {job_id: "12345", arguments: "arguments", job_class: "JobClass", queue: "queue"}
      j = Job.last
      expect(j.job_id).to eq("12345")
      expect(j.arguments).to eq("arguments")
      expect(j.job_class).to eq("JobClass")
      expect(j.status).to eq("started")
      expect(j.queue).to eq("queue")
      expect(response).to have_http_status(:success)
    end

    it "doesn't have response success when missing paramters" do
      post "/api/v1/jobs", params: {}
      expect(Job.count).to eq(0)
      expect(response).to have_http_status(:bad_request)
    end
  end
  describe "POST /api/v1/jobs/:job_id/complete" do
    context "a job that exists" do
      it "creates a new status 'complete'" do
        j = create(:job)
        post "/api/v1/jobs/#{j.job_id}/complete"
        expect(Job.last.status).to eq("complete")
        expect(Status.last.name).to eq("complete")
        expect(response).to have_http_status(:success)
      end
    end
    context "a job that doesn't exist" do
      subject do
        post "/api/v1/jobs/my-job-id/complete", params: {arguments: "arguments", job_class: "JobClass", queue: "queue"}
      end
      it "creates a new job with status complete" do
        subject
        expect(Job.last.job_id).to eq("my-job-id")
        expect(Job.last.status).to eq("complete")
        expect(response).to have_http_status(:success)
      end
      it "does not have any status with started" do
        subject
        job = Job.last
        expect(job.statuses.count).to eq(1)
        expect(job.status).to eq("complete")
      end
    end
    context "no job and inadequeate params" do
      it "doesn't create a Job and returns 400" do
        post "/api/v1/jobs/my-job-id/complete", params: {}
        expect(Job.count).to eq(0)
      expect(response).to have_http_status(:bad_request)
      end
    end
    
  end

end
