# frozen_string_literal: true

module Greensub
  class ProductsController < ApplicationController
    before_action :set_product, only: %i[show edit update destroy add remove purchase]

    def index
      # if params[:institution_id].present?
      #   @institution = Institution.find(params[:institution_id])
      #   @products = @institution.products.filter_by(filtering_params(params)).order(name: :asc).page(params[:page])
      if params[:component_id].present?
        @component = Component.find(params[:component_id])
        @products = @component.products.filter_by(filtering_params(params)).order(name: :asc).page(params[:page])
      elsif params[:individual_id].present?
        @individual = Individual.find(params[:individual_id])
        @products = @individual.products.filter_by(filtering_params(params)).order(name: :asc).page(params[:page])
      elsif params[:institution_id].present?
        @institution = Institution.find(params[:institution_id])
        @products = @institution.products.filter_by(filtering_params(params)).order(name: :asc).page(params[:page])
      else
        @products = Product.filter_by(filtering_params(params)).order(name: :asc).page(params[:page])
      end
    end

    def show; end

    def new
      @product = Product.new
    end

    def edit; end

    def create # rubocop:disable  Metrics/PerceivedComplexity
      if params[:component_id].present?
        component = Component.find(params[:component_id])
        @product = Product.find(params[:id])
        if @product.present? && component.present? && !@product.components.include?(component)
          @product.components << component
        end
        redirect_to component
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

    def destroy
      if params[:component_id].present?
        component = Component.find(params[:component_id])
        @product = Product.find(params[:id])
        if @product.present? && component.present? && @product.components.include?(component)
          @product.components.delete(component)
        end
        redirect_to component
      else
        @product.destroy
        respond_to do |format|
          format.html { redirect_to greensub_products_url, notice: 'Product was successfully destroyed.' }
          format.json { head :no_content }
        end
      end
    end

    def purchase
      redirect_to @product.purchase
    end

    private

      def set_product
        @product = Product.find(params[:id])
      end

      def product_params
        params.require(:greensub_product).permit(:identifier, :name, :purchase)
      end

      def filtering_params(params)
        params.slice(:identifier_like, :name_like, :purchase_like)
      end
  end
end
