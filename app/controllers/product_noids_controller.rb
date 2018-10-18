# frozen_string_literal: true

class ProductNoidsController < ApplicationController
  before_action :set_product_noid, only: %i[show edit update destroy]

  # GET /product_noids
  # GET /product_noids.json
  def index
    @product_noids = ProductNoid.all
  end

  # GET /product_noids/1
  # GET /product_noids/1.json
  def show; end

  # GET /product_noids/new
  def new
    @product_noid = ProductNoid.new
  end

  # GET /product_noids/1/edit
  def edit; end

  # POST /product_noids
  # POST /product_noids.json
  def create
    @product_noid = ProductNoid.new(product_noid_params)
    respond_to do |format|
      if @product_noid.save
        format.html { redirect_to @product_noid, notice: 'Product NOID was successfully created.' }
        format.json { render :show, status: :created, location: @product_noid }
      else
        format.html { render :new }
        format.json { render json: @product_noid.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /product_noids/1
  # PATCH/PUT /product_noids/1.json
  def update
    respond_to do |format|
      if @product_noid.update(product_noid_params)
        format.html { redirect_to @product_noid, notice: 'Product NOID was successfully updated.' }
        format.json { render :show, status: :ok, location: @product_noid }
      else
        format.html { render :edit }
        format.json { render json: @product_noid.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /product_noids/1
  # DELETE /product_noids/1.json
  def destroy
    @product_noid.destroy
    respond_to do |format|
      format.html { redirect_to product_noids_url, notice: 'Product NOID was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

    # Use callbacks to share common setup or constraints between actions.
    def set_product_noid
      @product_noid = ProductNoid.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def product_noid_params
      params.require(:product_noid).permit(:product, :noid)
    end
end
