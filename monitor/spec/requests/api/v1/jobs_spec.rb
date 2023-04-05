require 'rails_helper'

RSpec.describe "Api::V1::Jobs", type: :request do
  describe "POST /" do
    it "returns http success" do
      post "/api/v1/jobs", params: {job_id: "12345", arguments: "arguments", job_class: "JobClass"}
      j = Job.last
      expect(j.job_id).to eq("12345")
      expect(j.arguments).to eq("arguments")
      expect(j.job_class).to eq("JobClass")
      expect(j.status).to eq("started")
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
        Job.create(job_id: "12345", arguments: "arguments", job_class: "JobClass")
        post "/api/v1/jobs/12345/complete"
        expect(Job.last.status).to eq("complete")
        expect(Status.last.name).to eq("complete")
      end
    end
    
  end

end
