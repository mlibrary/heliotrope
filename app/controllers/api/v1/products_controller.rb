# frozen_string_literal: true

module API
  module V1
    class ProductsController < API::ApplicationController
      before_action :set_product, only: %i[show update destroy]

      def find
        @product = Product.find_by(identifier: params[:identifier])
        return head :not_found if @product.blank?
        render :show
      end

      def index
        @products = []
        if params[:lessee_id].present?
          set_lessee!
          @products = @lessee.products
        else
          @products = Product.all
        end
      end

      def show
        return head :not_found if @product.blank?
        if params[:lessee_id].present? # rubocop:disable Style/GuardClause
          lessee = Lessee.find_by(id: params[:lessee_id])
          return head :not_found if lessee.blank?
          return head :not_found unless lessee.products.include?(@product)
        end
      end

      def create
        if params[:lessee_id].present?
          create_lessee_product
        else
          create_product
        end
      end

      def update
        if params[:lessee_id].present?
          update_lessee_product
        else
          update_product
        end
      end

      def destroy
        if params[:lessee_id].present?
          set_lessee!
          @lessee.products.delete(@product) if @lessee.products.include?(@product)
        else
          return head :ok if @product.blank?
          return head :accepted unless @product.lessees.empty?
          @product.delete
        end
        head :ok
      end

      private

        def create_product
          status = :ok
          @product = Product.find_by(identifier: product_params[:identifier])
          if @product.blank?
            @product = Product.new(product_params)
            return render json: @product.errors, status: :unprocessable_entity unless @product.save
            status = :created
          end
          render :show, status: status, location: @product
        end

        def create_lessee_product
          status = :ok
          set_lessee!
          @product = Product.find_by(identifier: product_params[:identifier])
          if @product.blank?
            @product = Product.new(product_params)
            return render json: @product.errors, status: :unprocessable_entity unless @product.save
            status = :created
          end
          unless @lessee.products.include?(@product)
            @lessee.products << @product
            @lessee.save
          end
          render :show, status: status, location: @product
        end

        def update_product
          status = :ok
          if @product.blank?
            @product = Product.new(identifier: params[:identifier])
            return render json: @product.errors, status: :unprocessable_entity unless @product.save
            status = :created
          end
          render :show, status: status, location: @product
        end

        def update_lessee_product
          set_lessee!
          set_product!
          unless @lessee.products.include?(@product)
            @lessee.products << @product
            @lessee.save
          end
          render :show, status: :ok, location: @product
        end

        def set_lessee!
          @lessee = Lessee.find_by!(id: params[:lessee_id])
        end

        def set_product!
          @product = Product.find_by!(id: params[:id])
        end

        # Use callbacks to share common setup or constraints between actions.
        def set_product
          @product = Product.find_by(id: params[:id])
        end

        # Never trust parameters from the scary internet, only allow the white list through.
        def product_params
          params.require(:product).permit(:identifier, :purchase)
        end
    end
  end
end
