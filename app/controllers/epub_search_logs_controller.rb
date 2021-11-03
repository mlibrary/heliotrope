# frozen_string_literal: true

class EpubSearchLogsController < ApplicationController
  def index
    @epub_search_logs = EpubSearchLog.filter_by(filtering_params(params)).order(params[:sort] || "created_at desc").page(params[:page]).per(1000)
    @csv_url = request.original_url.gsub!(/epub_search_logs/, "epub_search_logs.csv")

    respond_to do |format|
      format.html
      format.csv { send_data @epub_search_logs.to_csv, filename: "epub-search-log-#{Time.zone.today}.csv" }
    end
  end

  private

    def filtering_params(params)
      params.slice(:query_like, :created_like, :noid_like, :time_like, :hits_like, :user_like, :press_like)
    end
end
