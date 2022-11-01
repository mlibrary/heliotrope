# frozen_string_literal: true

class HandleDepositsController < ApplicationController
  def index
    @handle_deposits = HandleDeposit.filter_by(filtering_params(params)).order(updated_at: :desc, verified: :asc, action: :desc, handle: :asc).page(params[:page])
  end

  private

    def filtering_params(params)
      params.slice(:handle_like, :url_value_like, :action_like, :verified_like)
    end
end
