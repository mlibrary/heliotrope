# frozen_string_literal: true

module API
  module V1
    # Components Controller
    class ComponentsController < API::ApplicationController
      before_action :set_component, only: %i[show update destroy]

      # Get component by identifier
      # @example
      #   get /api/component?identifier=String
      # @param [Hash] params { identifier: String }
      # @return [ActionDispatch::Response] {Greensub::Component} (see {show})
      def find
        @component = Greensub::Component.find_by(identifier: params[:identifier])
        return head :not_found if @component.blank?
        render :show
      end

      # @overload index
      #   List components
      #   @example
      #     get /api/components
      #   @return [ActionDispatch::Response] array of {Greensub::Component}
      # @overload index
      #   List product components
      #   @example
      #     get /api/products/:product_id/components
      #   @param [Hash] params { product_id: Number }
      #   @return [ActionDispatch::Response] array of {Greensub::Component}
      #
      #     (See ./app/views/api/v1/component/index.json.jbuilder)
      #
      #     {include:file:app/views/api/v1/components/index.json.jbuilder}
      #
      #     (See ./app/views/api/v1/component/_component.json.jbuilder)
      #
      #     {include:file:app/views/api/v1/components/_component.json.jbuilder}
      def index
        @components = if params[:product_id].present?
          set_product
          @product.components
        else
          Greensub::Component.all
        end
      end

      # @overload show
      #   Get component by id
      #   @example
      #     get /api/component/:id
      #   @param [Hash] params { id: Number }
      #   @return [ActionDispatch::Response] {Greensub::Component}
      #
      #     (See ./app/views/api/v1/component/show.json.jbuilder)
      #
      #     {include:file:app/views/api/v1/components/show.json.jbuilder}
      #
      #     (See ./app/views/api/v1/component/_component.json.jbuilder)
      #
      #     {include:file:app/views/api/v1/components/_component.json.jbuilder}
      # @overload show
      #   Get product component
      #   @example
      #     get /api/products/:product_id/components/:id
      #   @param [Hash] params { product_id: Number, id: Number }
      #   @return [ActionDispatch::Response]
      def show
        if params[:product_id].present? # rubocop:disable Style/GuardClause
          set_product
          return head :not_found unless @component.products.include?(@product)
        end
      end

      # Create component
      # @example
      #   post /api/components
      # @param [Hash] params { component: { identifier: String, name: String, noid: String } }
      # @return [ActionDispatch::Response] {Greensub::Component} (see {show})
      def create
        @component = Greensub::Component.find_by(identifier: component_params[:identifier])
        if @component.present?
          @component.errors.add(:identifier, "component identifier #{component_params[:identifier]} exists!")
          return render json: @component.errors, status: :unprocessable_entity
        end
        @component = Greensub::Component.new(component_params)
        unless Sighrax.factory(component_params[:noid]).valid?
          @component.errors.add(:noid, "component noid '#{component_params[:noid]}' does not exists!")
          return render json: @component.errors, status: :unprocessable_entity
        end
        return render json: @component.errors, status: :unprocessable_entity unless @component.save
        render :show, status: :created, location: @component
      end

      # @overload update
      #   Update component
      #   @example
      #     put /api/components/:id
      #   @param [Hash] params { id: Number, component: { name: String, email: String } }
      #   @return [ActionDispatch::Response] {Greensub::Component} (see {show})
      # @overload update
      #   Add component to product
      #   @example
      #     put /api/products/:product_id/components/:id
      #   @param [Hash] params { product_id: Number, id: Number }
      #   @return [ActionDispatch::Response]
      def update
        if params[:product_id].present?
          set_product
          unless @component.products.include?(@product)
            @component.products << @product
            @component.save
          end
          return head :ok
        end
        unless Sighrax.factory(component_params[:noid]).valid?
          @component.errors.add(:noid, "component noid '#{component_params[:noid]}' does not exists!")
          return render json: @component.errors, status: :unprocessable_entity
        end
        return render json: @component.errors, status: :unprocessable_entity unless @component.update(component_params)
        render :show, status: :ok, location: @component
      end

      # @overload destroy
      #   Delete component
      #   @example
      #     delete /api/components/:id
      #   @param [Hash] params { id: Number }
      #   @return [ActionDispatch::Response]
      # @overload destroy
      #   Remove component from product
      #   @example
      #     put /api/products/:product_id/components/:id
      #   @param [Hash] params { product_id: Number, id: Number }
      #   @return [ActionDispatch::Response]
      def destroy
        if params[:product_id].present?
          set_product
          @component.products.delete(@product) if @component.products.include?(@product)
        else
          return render json: @component.errors, status: :accepted unless @component.destroy
        end
        head :ok
      end

      private
        def set_product
          @product = Greensub::Product.find(params[:product_id])
        end

        def set_component
          @component = Greensub::Component.find(params[:id])
        end

        def component_params
          params.require(:component).permit(:identifier, :name, :noid)
        end
    end
  end
end
