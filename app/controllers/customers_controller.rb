# frozen_string_literal: true

class CustomersController < ApplicationController
  before_action :set_customer, only: %i[show]

  # GET /customers
  # GET /customers.json
  def index
    @customers = Institution.all
  end

  # GET /customers/1
  # GET /customers/1.json
  def show; end

  private

    # Use callbacks to share common setup or constraints between actions.
    def set_customer
      @customer = Institution.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def customer_params
      params.require(:customer).permit
    end
end
