# frozen_string_literal: true

class AptrustLogsController < ApplicationController
  def index
    @aptrust_logs = AptrustLog.filter(filtering_params(params)).order(created_at: :desc).page(params[:page])
  end

  private

    def filtering_params(params)
      params.slice(:noid_like, :where_like, :stage_like, :status_like, :action_like)
    end
end
