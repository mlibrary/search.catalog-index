class Api::V1::JobsController < ApplicationController
  def create
    @job = Job.new(job_params) 
    if @job.save
      Status.create(job: @job, name: "started")
      render :status => :ok
    else
      render :status => :bad_request
    end
  end

  def complete
    @job = Job.find_or_initialize_by(job_id: params[:job_id])  do |j|
      j.arguments = params[:arguments]
      j.job_class = params[:job_class]
      j.queue = params[:queue]
    end
    if @job.save
      Status.create(job: @job, name: "complete")
      render :status => :ok
    else
      render :status => :bad_request
    end
  end
  
  private
  def job_params
    params.permit(:job_id, :arguments, :job_class, :queue)
  end
end
