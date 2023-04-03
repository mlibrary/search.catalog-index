require 'rails_helper'

RSpec.describe Job, type: :model do
  let(:job) do
    {
      job_id: "job_id", 
      job_class: "job_class", 
      arguments: "arguments"
    }
  end
  it "has an id, class, and arguments" do
    j = Job.create(**job)
    expect(j.job_id).to eq("job_id")
    expect(j.job_class).to eq("job_class")
    expect(j.arguments).to eq("arguments")
  end
  context "after creating a job" do
    it "also creates a started status" do
      j = Job.create(**job)
      expect(j.status).to eq("started")
    end
  end
end
