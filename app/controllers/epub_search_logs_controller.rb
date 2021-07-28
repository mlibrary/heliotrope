# frozen_string_literal: true

class EpubSearchLogsController < ApplicationController
  def index
    @epub_search_logs = EpubSearchLog.filter_by(filtering_params(params)).order(params[:sort] || "created_at desc").page(params[:page]).per(1000)
  end

  private

    def filtering_params(params)
      params.slice(:query_like, :created_like, :noid_like, :time_like, :hits_like)
    end
end
