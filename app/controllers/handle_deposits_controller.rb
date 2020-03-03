# frozen_string_literal: true

class HandleDepositsController < ApplicationController
  def index
    @handle_deposits = HandleDeposit.filter(filtering_params(params)).order(updated_at: :desc, verified: :asc, action: :desc, noid: :asc).page(params[:page])
  end

  private

    def filtering_params(params)
      params.slice(:noid_like, :action_like, :verified_like)
    end
end
