require 'rails_helper'

RSpec.describe Status, type: :model do
  let(:job) do
    {
      job_id: "job_id", 
      job_class: "job_class", 
      arguments: "arguments"
    }
  end
  context "name" do
    it "has :started for 0" do
      j = Job.create(**job)
      s = Status.create(name: 0, job: j)
      expect(s.name).to eq("started")
    end
  end
end
