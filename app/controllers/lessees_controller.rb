# frozen_string_literal: true

class LesseesController < ApplicationController
  before_action :set_lessee, only: %i[show edit update destroy add remove]

  # GET /lessees
  # GET /lessees.json
  def index
    @lessees = Lessee.all
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
  def create # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
    if params[:product_id].present? || params[:grouping_id].present?
      if params[:product_id].present?
        product = Product.find(params[:product_id])
        @lessee = Lessee.find(params[:id])
        if product.present? && @lessee.present? && !product.lessees.include?(@lessee)
          product.lessees << @lessee
        end
        redirect_to product
      else # params[:grouping_id].present?
        grouping = Grouping.find(params[:grouping_id])
        @lessee = Lessee.find(params[:id])
        if grouping.present? && @lessee.present? && !grouping.lessees.include?(@lessee)
          grouping.lessees << @lessee
        end
        redirect_to grouping
      end
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

  # PATCH/PUT /lessees/1
  # PATCH/PUT /lessees/1.json
  def update
    respond_to do |format|
      if @lessee.update(lessee_params)
        format.html { redirect_to @lessee, notice: 'Lessee was successfully updated.' }
        format.json { render :show, status: :ok, location: @lessee }
      else
        format.html { render :edit }
        format.json { render json: @lessee.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /lessees/1
  # DELETE /lessees/1.json
  # DELETE /products/product_id:/lessees/:id
  def destroy # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
    if params[:product_id].present? || params[:grouping_id].present?
      if params[:product_id].present?
        product = Product.find(params[:product_id])
        if product.present? && @lessee.present? && product.lessees.include?(@lessee)
          product.lessees.delete(@lessee)
        end
        redirect_to product
      else # params[:grouping_id].present?
        grouping = Grouping.find(params[:grouping_id])
        if grouping.present? && @lessee.present? && grouping.lessees.include?(@lessee)
          grouping.lessees.delete(@lessee)
        end
        redirect_to grouping
      end
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
end
