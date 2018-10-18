# frozen_string_literal: true

class ProductsController < ApplicationController
  before_action :set_product, only: %i[show edit update destroy add remove purchase help]

  # GET /products
  # GET /products.json
  def index
    @products = Product.order(name: :asc).page(params[:page])
  end

  # GET /products/1
  # GET /products/1.json
  def show; end

  # GET /products/new
  def new
    @product = Product.new
  end

  # GET /products/1/edit
  def edit; end

  # POST /products
  # POST /products.json
  # POST /components/:component_id/products
  # POST /lessees/:lessee_id/products
  def create # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
    if params[:component_id].present? || params[:lessee_id].present?
      if params[:component_id].present?
        component = Component.find(params[:component_id])
        @product = Product.find(params[:id])
        if @product.present? && component.present? && !@product.components.include?(component)
          @product.components << component
        end
        redirect_to component
      else # params[:lessee_id].present?
        lessee = Lessee.find(params[:lessee_id])
        @product = Product.find(params[:id])
        if @product.present? && lessee.present? && !@product.lessees.include?(lessee)
          @product.lessees << lessee
        end
        redirect_to lessee
      end
    else
      @product = Product.new(product_params)
      respond_to do |format|
        if @product.save
          format.html { redirect_to @product, notice: 'Product was successfully created.' }
          format.json { render :show, status: :created, location: @product }
        else
          format.html { render :new }
          format.json { render json: @product.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  # PATCH/PUT /products/1
  # PATCH/PUT /products/1.json
  def update
    respond_to do |format|
      if @product.update(product_params)
        format.html { redirect_to @product, notice: 'Product was successfully updated.' }
        format.json { render :show, status: :ok, location: @product }
      else
        format.html { render :edit }
        format.json { render json: @product.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /products/1
  # DELETE /products/1.json
  # POST /components/:component_id/products/:id
  # POST /lessees/:lessee_id/products/:id
  def destroy # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
    if params[:component_id].present? || params[:lessee_id].present?
      if params[:component_id].present?
        component = Component.find(params[:component_id])
        @product = Product.find(params[:id])
        if @product.present? && component.present? && @product.components.include?(component)
          @product.components.delete(component)
        end
        redirect_to component
      else # params[:lessee_id].present?
        lessee = Lessee.find(params[:lessee_id])
        @product = Product.find(params[:id])
        if @product.present? && lessee.present? && @product.lessees.include?(lessee)
          @product.lessees.delete(lessee)
        end
        redirect_to lessee
      end
    else
      @product.destroy
      respond_to do |format|
        format.html { redirect_to products_url, notice: 'Product was successfully destroyed.' }
        format.json { head :no_content }
      end
    end
  end

  # GET /products/1/purchase
  def purchase
    redirect_to @product.purchase
  end

  # GET /products/1/help
  def help; end

  private

    # Use callbacks to share common setup or constraints between actions.
    def set_product
      @product = Product.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def product_params
      params.require(:product).permit(:identifier, :name, :purchase)
    end

    # A list of the param names that can be used for filtering the Product list
    def filtering_params(params)
      params.slice(:identifier_like, :name_like)
    end
end
