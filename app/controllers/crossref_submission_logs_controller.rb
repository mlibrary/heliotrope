# frozen_string_literal: true

class CrossrefSubmissionLogsController < ApplicationController
  def index
    @crossref_submission_logs = CrossrefSubmissionLog.filter(filtering_params(params)).order(created_at: :desc).page(params[:page])
  end

  def show
    if allowed_show_params(params[:file])
      @file = CrossrefSubmissionLog.find(params[:id]).public_send(params[:file])
    else
      render 'hyrax/base/unauthorized', status: :unauthorized
    end
  end

  private
    def allowed_show_params(filename)
      ['submission_xml', 'response_xml', 'initial_http_message'].include? filename
    end

    def filtering_params(params)
      params.slice(:doi_batch_id_like, :file_name_like, :status_like, :created_at_like, :updated_at_like)
    end
end
