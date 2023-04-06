require "action_view"
module JobManager
  include ActionView::Helpers::DateHelper
  extend self
  # Lists the unfinished jobs for a given string
  # @param str [String] String that matches something in the arguments string
  def uncompleted_jobs(str = nil)
    _jobs(str).select{|j| j.status != "complete" }
  end

  def completed_jobs(str = nil)
    _jobs(str).select{|j| j.status == "complete" }
  end

  def jobs(str = nil)
    _jobs(str)
  end
  def restart_uncompleted_jobs(str, sidekiq_client=Sidekiq::Client, logger=Logger.new($stdout))
    jobs = self.uncompleted_jobs(str)
    jobs.each do |j|
      logger.info "requeuing class => #{j.job_class}\tqueue => #{j.queue}\targs=>#{JSON.parse(j.arguments)}"
      sidekiq_client.push_bulk("class" => j.job_class, "queue" => j.queue, "args" => [JSON.parse(j.arguments)])
      j.destroy
    end
  end
  def completed_jobs_duration(str = nil)
    completed_jobs(str).each do |j|
      if j.duration
        puts "#{distance_of_time_in_words(j.duration)}\tclass=>#{j.job_class}\tqueue => #{j.queue}\targs=>#{JSON.parse(j.arguments)}"
      end
    end
    return
  end
  private
  def _jobs(str)
    str.nil? ? Job.all : Job.for_job_string(str)
  end
end
