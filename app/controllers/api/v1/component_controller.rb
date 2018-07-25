# frozen_string_literal: true

module API
  module V1
    # Components Controller
    class ComponentsController < API::ApplicationController
      before_action :set_component, only: %i[show update destroy]
      # @example get /api/component?identifier=String
      # @param [Hash] params { identifier: String }
      # @return [ActionDispatch::Response] {Component}
      #   (See ./app/views/api/v1/components/show.json.jbuilder for details)
      def find
        @component = Component.find_by(identifier: params[:identifier])
        return head :not_found if @component.blank?
        render :show
      end

      # @overload index
      #   @example get /api/components
      # @overload index
      #   @example get /api/products/:product_id/components
      #   @param [Hash] params { product_id: Number }
      # @return [ActionDispatch::Response] array of {Component}
      #   (See ./app/views/api/v1/components/index.json.jbuilder for details)
      def index
        @components = []
        if params[:product_id].present?
          set_product!
          @components = @product.components
        else
          @components = Component.all
        end
      end

      # @overload show
      #   @example get /api/components/:id
      #   @param [Hash] params { id: Number }
      # @overload show
      #   @example get /api/products/:product_id/components/:id
      #   @param [Hash] params { product_id: Number, id: Number }
      # @return [ActionDispatch::Response] {Component}
      #   (See ./app/views/api/v1/components/show.json.jbuilder for details)
      def show
        return head :not_found if @component.blank?
        if params[:product_id].present? # rubocop:disable Style/GuardClause
          product = Product.find_by(id: params[:product_id])
          return head :not_found if product.blank?
          return head :not_found unless product.components.include?(@component)
        end
      end

      # @overload create
      #   post /api/components
      #   @param [Hash] params { component: { identifier: String } }
      # @overload create
      #   post /api/products/:product_id/components
      #   @param [Hash] params { product_id: Number, component: { identifier: String } }
      # @return [ActionDispatch::Response] {Component}
      #   (See ./app/views/api/v1/components/show.json.jbuilder for details)
      def create
        if params[:product_id].present?
          create_product_component
        else
          create_component
        end
      end

      # @overload update
      #   @example put /api/components/:id
      #   @param [Hash] params { id: Number }
      # @overload update
      #   @example put /api/products/:product_id/components/:id
      #   @param [Hash] params { product_id: Number, id: Number }
      # @return [ActionDispatch::Response] {Component}
      #   (See ./app/views/api/v1/components/show.json.jbuilder for details)
      def update
        if params[:product_id].present?
          update_product_component
        else
          update_component
        end
      end

      # @overload destroy
      #   @example delete /api/components/:id
      #   @param [Hash] params { id: Number }
      # @overload destroy
      #   @example delete /api/products/:product_id/components/:id
      #   @param [Hash] params { product_id: Number, id: Number }
      # @return [ActionDispatch::Response]
      def destroy
        if params[:product_id].present?
          set_product!
          @product.components.delete(@component) if @product.components.include?(@component)
        else
          return head :ok if @component.blank?
          return head :accepted unless @component.products.empty?
          @component.delete
        end
        head :ok
      end

      private

        def create_component
          status = :ok
          @component = Component.find_by(identifier: component_params[:identifier])
          if @component.blank?
            @component = Component.new(component_params)
            return render json: @component.errors, status: :unprocessable_entity unless @component.save
            status = :created
          end
          render :show, status: status, location: @component
        end

        def create_product_component
          status = :ok
          set_product!
          @component = Component.find_by(identifier: component_params[:identifier])
          if @component.blank?
            @component = Component.new(component_params)
            return render json: @component.errors, status: :unprocessable_entity unless @component.save
            status = :created
          end
          unless @product.components.include?(@component)
            @product.components << @component
            @product.save
          end
          render :show, status: status, location: @component
        end

        def update_component
          status = :ok
          if @component.blank?
            @component = Component.new(identifier: params[:identifier])
            return render json: @component.errors, status: :unprocessable_entity unless @component.save
            status = :created
          end
          render :show, status: status, location: @component
        end

        def update_product_component
          set_product!
          set_component!
          unless @product.components.include?(@component)
            @product.components << @component
            @product.save
          end
          render :show, status: :ok, location: @component
        end

        def set_product!
          @product = Product.find_by!(id: params[:product_id])
        end

        def set_component!
          @component = Component.find_by!(id: params[:id])
        end

        # Use callbacks to share common setup or constraints between actions.
        def set_component
          @component = Component.find_by(id: params[:id])
        end

        # Never trust parameters from the scary internet, only allow the white list through.
        def component_params
          params.require(:component).permit(:identifier)
        end
    end
  end
end
