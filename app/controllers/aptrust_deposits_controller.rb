# frozen_string_literal: true

class AptrustDepositsController < ApplicationController
  before_action :set_aptrust_deposit, only: %i[destroy]

  def index
    @aptrust_deposits = AptrustDeposit.filter(filtering_params(params)).order(created_at: :desc).page(params[:page])
  end

  def destroy
    @aptrust_deposit.destroy
    respond_to do |format|
      format.html { redirect_to aptrust_deposits_url, notice: 'APTrust Deposit was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

    def set_aptrust_deposit
      @aptrust_deposit = AptrustDeposit.find(params[:id])
    end

    def filtering_params(params)
      params.slice(:noid_like, :identifier_like)
    end
end
