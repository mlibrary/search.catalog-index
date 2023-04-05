class Api::V1::JobsController < ApplicationController
  def create
    @job = Job.new(job_params) 
    if @job.save
      render :status => :ok
    else
      render :status => :bad_request
    end
  end

  def complete
    job = Job.find_by(job_id: params[:job_id])
    if job 
      Status.create(job: job, name: "complete")
      render :status => :ok
    else
      render :status => :bad_request
    end
  end
  
  private
  def job_params
    params.permit(:job_id, :arguments, :job_class)
  end
end
