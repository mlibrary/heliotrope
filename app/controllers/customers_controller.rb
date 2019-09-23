# frozen_string_literal: true

class CustomersController < ApplicationController
  before_action :set_customer, only: %i[show]

  def index
    @customers = Greensub::Institution.all
  end

  def show; end

  private

    def set_customer
      @customer = Greensub::Institution.find(params[:id])
    end

    def customer_params
      params.require(:customer).permit
    end
end
