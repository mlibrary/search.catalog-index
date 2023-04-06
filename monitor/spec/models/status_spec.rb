require 'rails_helper'

RSpec.describe Status, type: :model do
  context "name" do
    it "has :started for 0" do
      j = create(:job)
      s = Status.create(name: 0, job: j)
      expect(s.name).to eq("started")
    end
  end
end
