class Job < ApplicationRecord
  has_many :statuses, dependent: :destroy
  validates :job_id, :arguments, :job_class, :queue, presence: true

  def self.for_job_string(str)
    Job.select do |j|
      j.arguments.match?(str)
    end
  end
  def status
    self.statuses.order(:created_at).last.name
  end
  
  def duration
    started = self.statuses.find_by(name: "started")
    completed = self.statuses.find_by(name: "complete")
    return if started.nil? || completed.nil?
    completed.created_at - started.created_at
  end

end
