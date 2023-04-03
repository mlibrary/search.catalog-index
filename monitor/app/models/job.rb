class Job < ApplicationRecord
  has_many :statuses

  after_create :mark_as_started

  def status
    self.statuses.order(:created_at).last.name
  end

  private
  def mark_as_started
    Status.create(job: self, name: "started")
  end
end
