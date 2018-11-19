# frozen_string_literal: true

class LesseesController < ApplicationController
  before_action :set_lessee, only: %i[show edit update destroy add remove]

  # GET /lessees
  # GET /lessees.json
  def index
    @lessees = Lessee.order(identifier: :asc).page(params[:page])
  end

  # GET /lessees/1
  # GET /lessees/1.json
  def show; end

  # GET /lessees/new
  def new
    @lessee = Lessee.new
  end

  # GET /lessees/1/edit
  def edit; end

  # POST /lessees
  # POST /lessees.json
  # POST /products/product_id:/lessees
  def create # rubocop:disable Metrics/PerceivedComplexity
    if params[:product_id].present?
      product = Product.find(params[:product_id])
      @lessee = Lessee.find(params[:id])
      if product.present? && @lessee.present? && !product.lessees.include?(@lessee)
        product.lessees << @lessee
      end
      redirect_to product
    else
      @lessee = Lessee.new(lessee_params)
      respond_to do |format|
        if @lessee.save
          format.html { redirect_to @lessee, notice: 'Lessee was successfully created.' }
          format.json { render :show, status: :created, location: @lessee }
        else
          format.html { render :new }
          format.json { render json: @lessee.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  # DELETE /lessees/1
  # DELETE /lessees/1.json
  # DELETE /products/product_id:/lessees/:id
  def destroy
    if params[:product_id].present?
      product = Product.find(params[:product_id])
      if product.present? && @lessee.present? && product.lessees.include?(@lessee)
        product.lessees.delete(@lessee)
      end
      redirect_to product
    else
      @lessee.destroy
      respond_to do |format|
        format.html { redirect_to lessees_url, notice: 'Lessee was successfully destroyed.' }
        format.json { head :no_content }
      end
    end
  end

  private

    # Use callbacks to share common setup or constraints between actions.
    def set_lessee
      @lessee = Lessee.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def lessee_params
      params.require(:lessee).permit(:identifier)
    end

    # A list of the param names that can be used for filtering the Product list
    def filtering_params(params)
      params.slice(:identifier_like)
    end
end
