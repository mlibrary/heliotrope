# frozen_string_literal: true

class CrossrefSubmissionLogsController < ApplicationController
  def index
    @crossref_submission_logs = CrossrefSubmissionLog.filter(filtering_params(params)).order(created_at: :desc).page(params[:page])
  end

  def show
    @file = CrossrefSubmissionLog.find(params[:id]).public_send(params[:file])
  end

  private

    def filtering_params(params)
      params.slice(:doi_batch_id_like, :file_name_like, :status_like, :created_at_like, :updated_at_like)
    end
end
