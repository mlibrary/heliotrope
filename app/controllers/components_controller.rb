# frozen_string_literal: true

class ComponentsController < ApplicationController
  before_action :set_component, only: %i[show edit update destroy add remove]

  def index
    if params[:product_id].present?
      @product = Product.find(params[:product_id])
      @components = @product.components
    else
      @components = Component.all
    end
    @components = @components.filter(filtering_params(params)).order(identifier: :asc).page(params[:page])
  end

  def show; end

  def new
    @component = Component.new
  end

  def edit; end

  def create # rubocop:disable  Metrics/PerceivedComplexity
    if params[:product_id].present?
      product = Product.find(params[:product_id])
      @component = Component.find(params[:id])
      if product.present? && @component.present? && !product.components.include?(@component)
        product.components << @component
      end
      redirect_to product
    else
      @component = Component.new(component_params)
      respond_to do |format|
        if @component.save
          format.html { redirect_to @component, notice: 'Component was successfully created.' }
          format.json { render :show, status: :created, location: @component }
        else
          format.html { render :new }
          format.json { render json: @component.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  def update
    respond_to do |format|
      if @component.update(component_params)
        format.html { redirect_to @component, notice: 'Component was successfully updated.' }
        format.json { render :show, status: :ok, location: @component }
      else
        format.html { render :edit }
        format.json { render json: @component.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    if params[:product_id].present?
      product = Product.find(params[:product_id])
      if product.present? && @component.present? && product.components.include?(@component)
        product.components.delete(@component)
      end
      redirect_to product
    else
      @component.destroy
      respond_to do |format|
        format.html { redirect_to components_url, notice: 'Component was successfully destroyed.' }
        format.json { head :no_content }
      end
    end
  end

  private

    def set_component
      @component = Component.find(params[:id])
    end

    def component_params
      params.require(:component).permit(:identifier, :name, :noid, :handle)
    end

    def filtering_params(params)
      params.slice(:identifier_like, :name_like, :noid_like, :handle_like)
    end
end
