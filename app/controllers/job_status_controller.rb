# frozen_string_literal: true

class JobStatusController < ApplicationController
  def show
    @job_status = JobStatus.find(params[:id])
    # We want this page to be press branded and have press GA4
    @press = Press.find(params[:press_id])

    @download_redirect = params[:download_redirect]

    # Return a basic HTML page and a JSON version for polling
    respond_to do |format|
      format.html { render :show, layout: false }
      format.json do render json: { completed: @job_status.completed,
                                    redirect: @download_redirect,
                                    error: @job_status.error,
                                    error_message: @job_status.error_message }
                  end
    end
  end
end
