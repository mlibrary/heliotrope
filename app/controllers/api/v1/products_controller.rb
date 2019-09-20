# frozen_string_literal: true

module API
  module V1
    # Products Controller
    class ProductsController < API::ApplicationController
      before_action :set_product, only: %i[show update destroy]

      # Get product by identifier
      # @example
      #   get /api/product?identifier=String
      # @param [Hash] params { identifier: String }
      # @return [ActionDispatch::Response] {Greensub::Product} (see {show})
      def find
        @product = Greensub::Product.find_by(identifier: params[:identifier])
        return head :not_found if @product.blank?
        render :show
      end

      # @overload index
      #   List products
      #   @example
      #     get /api/products
      #   @return [ActionDispatch::Response] array of {Greensub::Product}
      # @overload index
      #   List component products
      #   @example
      #     get /api/components/:component_id/products
      #   @param [Hash] params { component_id: Number }
      #   @return [ActionDispatch::Response] array of {Greensub::Product}
      # @overload index
      #   List individual products
      #   @example
      #     get /api/individual/:individual_id/products
      #   @param [Hash] params { individual_id: Number }
      #   @return [ActionDispatch::Response] array of {Greensub::Product}
      # @overload index
      #   List institution products
      #   @example
      #     get /api/institution/:instituion_id/products
      #   @param [Hash] params { instituion_id: Number }
      #   @return [ActionDispatch::Response] array of {Greensub::Product}
      #
      #     (See ./app/views/api/v1/product/index.json.jbuilder)
      #
      #     {include:file:app/views/api/v1/products/index.json.jbuilder}
      #
      #     (See ./app/views/api/v1/product/_product.json.jbuilder)
      #
      #     {include:file:app/views/api/v1/products/_product.json.jbuilder}
      def index
        @products = if params[:component_id].present?
          set_component
          @component.products
        elsif params[:individual_id].present?
          set_individual
          @individual.products
        elsif params[:institution_id].present?
          set_institution
          @institution.products
        else
          Greensub::Product.all
        end
      end

      # Get product by id
      # @example
      #   get /api/product/:id
      # @param [Hash] params { id: Number }
      # @return [ActionDispatch::Response] {Greensub::Product}
      #
      #   (See ./app/views/api/v1/product/show.json.jbuilder)
      #
      #   {include:file:app/views/api/v1/products/show.json.jbuilder}
      #
      #   (See ./app/views/api/v1/product/_product.json.jbuilder)
      #
      #   {include:file:app/views/api/v1/products/_product.json.jbuilder}
      def show; end

      # Create product
      # @example
      #   post /api/products
      # @param [Hash] params { product: { identifier: String, name: String, email: String } }
      # @return [ActionDispatch::Response] {Greensub::Product} (see {show})
      def create
        @product = Greensub::Product.find_by(identifier: product_params[:identifier])
        if @product.present?
          @product.errors.add(:identifier, "product identifier #{product_params[:identifier]} exists!")
          return render json: @product.errors, status: :unprocessable_entity
        end
        @product = Greensub::Product.new(product_params)
        return render json: @product.errors, status: :unprocessable_entity unless @product.save
        render :show, status: :created, location: @product
      end

      # Update product
      # @example
      #   put /api/products/:id
      # @param [Hash] params { id: Number, product: { name: String, purchase: String } }
      # @return [ActionDispatch::Response] {Greensub::Product} (see {show})
      def update
        return render json: @product.errors, status: :unprocessable_entity unless @product.update(product_params)
        render :show, status: :ok, location: @product
      end

      # Delete product
      # @example
      #   delete /api/products/:id
      # @param [Hash] params { id: Number }
      # @return [ActionDispatch::Response]
      def destroy
        return render json: @product.errors, status: :accepted unless @product.destroy
        head :ok
      end

      private
        def set_component
          @component = Greensub::Component.find(params[:component_id])
        end

        def set_individual
          @individual = Greensub::Individual.find(params[:individual_id])
        end

        def set_institution
          @institution = Greensub::Institution.find(params[:institution_id])
        end

        def set_product
          @product = Greensub::Product.find(params[:id])
        end

        def product_params
          params.require(:product).permit(:identifier, :name, :purchase)
        end
    end
  end
end
