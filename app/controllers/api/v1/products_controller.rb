# frozen_string_literal: true

module API
  module V1
    # Products Controller
    class ProductsController < API::ApplicationController
      before_action :set_product, only: %i[show update destroy]
      # @example get /api/product?identifier=String
      # @param [Hash] params { identifier: String }
      # @return [ActionDispatch::Response] {Product}
      #   (See ./app/views/api/v1/products/show.json.jbuilder for details)
      def find
        @product = Product.find_by(identifier: params[:identifier])
        return head :not_found if @product.blank?
        render :show
      end

      # @overload index
      #   @example get /api/products
      # @overload index
      #   @example get /api/lessees/:lessee_id/products
      #   @param [Hash] params { lessee_id: Number }
      # @return [ActionDispatch::Response] array of {Product}
      #   (See ./app/views/api/v1/products/index.json.jbuilder for details)
      def index
        @products = []
        if params[:lessee_id].present?
          set_lessee!
          @products = @lessee.products
        else
          @products = Product.all
        end
      end

      # @overload show
      #   @example get /api/products/:id
      #   @param [Hash] params { id: Number }
      # @overload show
      #   @example get /api/lessees/:lessee_id/products/:id
      #   @param [Hash] params { lessee_id: Number, id: Number }
      # @return [ActionDispatch::Response] {Product}
      #   (See ./app/views/api/v1/products/show.json.jbuilder for details)
      def show
        return head :not_found if @product.blank?
        if params[:lessee_id].present? # rubocop:disable Style/GuardClause
          lessee = Lessee.find_by(id: params[:lessee_id])
          return head :not_found if lessee.blank?
          return head :not_found unless lessee.products.include?(@product)
        end
      end

      # @overload create
      #   post /api/products
      #   @param [Hash] params { product: { identifier: String } }
      # @overload create
      #   post /api/lessees/:lessee_id/products
      #   @param [Hash] params { lessee_id: Number, product: { identifier: String } }
      # @return [ActionDispatch::Response] {Product}
      #   (See ./app/views/api/v1/products/show.json.jbuilder for details)
      def create
        if params[:lessee_id].present?
          create_lessee_product
        else
          create_product
        end
      end

      # @overload update
      #   @example put /api/products/:id
      #   @param [Hash] params { id: Number }
      # @overload update
      #   @example put /api/lessees/:lessee_id/products/:id
      #   @param [Hash] params { lessee_id: Number, id: Number }
      # @return [ActionDispatch::Response] {Product}
      #   (See ./app/views/api/v1/products/show.json.jbuilder for details)
      def update
        if params[:lessee_id].present?
          update_lessee_product
        else
          update_product
        end
      end

      # @overload destroy
      #   @example delete /api/products/:id
      #   @param [Hash] params { id: Number }
      # @overload destroy
      #   @example delete /api/lessees/:lessee_id/products/:id
      #   @param [Hash] params { lessee_id: Number, id: Number }
      # @return [ActionDispatch::Response]
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
          params.require(:product).permit(:identifier, :name, :purchase)
        end
    end
  end
end
