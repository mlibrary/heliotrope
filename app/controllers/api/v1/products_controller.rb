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
      #   @example get /api/components/:component_id/products
      #   @param [Hash] params { component_id: Number }
      # @overload index
      #   @example get /api/lessees/:lessee_id/products
      #   @param [Hash] params { lessee_id: Number }
      # @return [ActionDispatch::Response] array of {Product}
      #   (See ./app/views/api/v1/products/index.json.jbuilder for details)
      def index
        @products = []
        if params[:component_id].present?
          set_component!
          @products = @component.products
        elsif params[:lessee_id].present?
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
      #   @example get /api/components/:component_id/products/:id
      #   @param [Hash] params { component_id: Number, id: Number }
      # @overload show
      #   @example get /api/lessees/:lessee_id/products/:id
      #   @param [Hash] params { lessee_id: Number, id: Number }
      # @return [ActionDispatch::Response] {Product}
      #   (See ./app/views/api/v1/products/show.json.jbuilder for details)
      def show # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
        return head :not_found if @product.blank?
        if params[:component_id].present?
          component = Component.find_by(id: params[:component_id])
          return head :not_found if component.blank?
          return head :not_found unless component.products.include?(@product)
        elsif params[:lessee_id].present?
          lessee = Lessee.find_by(id: params[:lessee_id])
          return head :not_found if lessee.blank?
          return head :not_found unless lessee.products.include?(@product)
        end
      end

      # @overload create
      #   post /api/products
      #   @param [Hash] params { product: { identifier: String } }
      # @overload create
      #   post /api/components/:component_id/products
      #   @param [Hash] params { component_id: Number, product: { identifier: String } }
      # @overload create
      #   post /api/lessees/:lessee_id/products
      #   @param [Hash] params { lessee_id: Number, product: { identifier: String } }
      # @return [ActionDispatch::Response] {Product}
      #   (See ./app/views/api/v1/products/show.json.jbuilder for details)
      def create
        if params[:component_id].present?
          create_component_product
        elsif params[:lessee_id].present?
          create_lessee_product
        else
          create_product
        end
      end

      # @overload update
      #   @example put /api/products/:id
      #   @param [Hash] params { id: Number }
      # @overload update
      #   @example put /api/components/:component_id/products/:id
      #   @param [Hash] params { component_id: Number, id: Number }
      # @overload update
      #   @example put /api/lessees/:lessee_id/products/:id
      #   @param [Hash] params { lessee_id: Number, id: Number }
      # @return [ActionDispatch::Response] {Product}
      #   (See ./app/views/api/v1/products/show.json.jbuilder for details)
      def update
        if params[:component_id].present?
          update_component_product
        elsif params[:lessee_id].present?
          update_lessee_product
        else
          update_product
        end
      end

      # @overload destroy
      #   @example delete /api/products/:id
      #   @param [Hash] params { id: Number }
      # @overload destroy
      #   @example delete /api/components/:component_id/products/:id
      #   @param [Hash] params { component_id: Number, id: Number }
      # @overload destroy
      #   @example delete /api/lessees/:lessee_id/products/:id
      #   @param [Hash] params { lessee_id: Number, id: Number }
      # @return [ActionDispatch::Response]
      def destroy # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
        if params[:component_id].present?
          set_component!
          @component.products.delete(@product) if @component.products.include?(@product)
        elsif params[:lessee_id].present?
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

        def create_component_product
          status = :ok
          set_component!
          @product = Product.find_by(identifier: product_params[:identifier])
          if @product.blank?
            @product = Product.new(product_params)
            return render json: @product.errors, status: :unprocessable_entity unless @product.save
            status = :created
          end
          unless @component.products.include?(@product)
            @component.products << @product
            @component.save
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
          if @product.update(product_params)
            render :show, status: :ok, location: @product
          else
            render json: @product.errors, status: :unprocessable_entity
          end
        end

        def update_component_product
          set_component!
          set_product!
          unless @component.products.include?(@product)
            @component.products << @product
            @component.save
          end
          render :show, status: :ok, location: @product
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

        def set_component!
          @component = Component.find_by!(id: params[:component_id])
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
