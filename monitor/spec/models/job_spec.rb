require 'rails_helper'

RSpec.describe Job, type: :model do
  it "has an id, class, and arguments" do
    j = create(:job)
    expect(j.job_id).to eq("job_id")
    expect(j.job_class).to eq("job_class")
    expect(j.arguments).to eq("arguments")
    expect(j.queue).to eq("queue")
  end
end
