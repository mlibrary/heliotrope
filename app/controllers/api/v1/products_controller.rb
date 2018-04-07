# frozen_string_literal: true

module API
  module V1
    class ProductsController < API::ApplicationController
      respond_to :json
      before_action :set_product, only: %i[show update destroy]

      def index
        @products = []
        if params[:lessee_identifier].present?
          lessee = Lessee.find_or_create_by!(identifier: params[:lessee_identifier]) do |_new_lessee|
            # new_product.attribute = 'https://www.umich.edu/'
          end
          @products = lessee.products
        else
          @products = Product.all
        end
      end

      def show
        return head :not_found if @product.blank?
        if params[:lessee_identifier].present? # rubocop:disable Style/GuardClause
          lessee = Lessee.find_by(identifier: params[:lessee_identifier])
          return head :not_found if lessee.blank?
          return head :not_found unless lessee.products.include?(@product)
        end
      end

      def create # rubocop:disable Metrics/CyclomaticComplexity
        status = :ok
        lessee = if params[:lessee_identifier].present?
                   Lessee.find_or_create_by!(identifier: params[:lessee_identifier]) do |_new_lessee|
                     # new_lessee.attribute = 'https://www.umich.edu/'
                   end
                 end
        @product = Product.find_by(identifier: product_params[:identifier])
        if @product.blank?
          @product = Product.new(product_params)
          @product.purchase = 'https://www.umich.edu/'
          return render json: @product.errors, status: :unprocessable_entity unless @product.save
          status = :created
        end
        if lessee.present? && @product.present? && !lessee.products.include?(@product)
          lessee.products << @product
        end
        render :show, status: status, location: @product
      end

      def update # rubocop:disable Metrics/CyclomaticComplexity
        status = :ok
        lessee = if params[:lessee_identifier].present?
                   Lessee.find_or_create_by!(identifier: params[:lessee_identifier]) do |_new_lessee|
                     # new_lessee.attribute = 'https://www.umich.edu/'
                   end
                 end
        if @product.blank?
          @product = Product.new(identifier: params[:identifier])
          @product.purchase = 'https://www.umich.edu/'
          return render json: @product.errors, status: :unprocessable_entity unless @product.save
          status = :created
        end
        if lessee.present? && @product.present? && !lessee.products.include?(@product)
          lessee.products << @product
        end
        render :show, status: status, location: @product
      end

      def destroy # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
        if params[:lessee_identifier].present?
          lessee = Lessee.find_by(identifier: params[:lessee_identifier])
          if lessee.present? && @product.present? && lessee.products.include?(@product)
            lessee.products.delete(@product)
          end
        else
          return head :ok if @product.blank?
          return head :accepted unless @product.lessees.empty?
          @product.delete
        end
        head :ok
      end

      private

        # Use callbacks to share common setup or constraints between actions.
        def set_product
          @product = Product.find_by(identifier: params[:identifier])
        end

        # Never trust parameters from the scary internet, only allow the white list through.
        def product_params
          params.require(:product).permit(:identifier, :purchase)
        end
    end
  end
end
