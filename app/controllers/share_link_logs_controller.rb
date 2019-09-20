# frozen_string_literal: true

class ShareLinkLogsController < ApplicationController
  def index
    @share_link_logs = ShareLinkLog.filter(filtering_params(params)).order(created_at: :desc).page(params[:page])
  end

  private
    def filtering_params(params)
      params.slice(:ip_address_like, :institution_like, :press_like, :title_like, :noid_like, :token_like, :action_like, :created_like)
    end
end
