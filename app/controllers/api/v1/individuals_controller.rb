# frozen_string_literal: true

module API
  module V1
    # Individuals Controller
    class IndividualsController < API::ApplicationController
      before_action :set_individual, only: %i[show update destroy]

      # Get individual by identifier
      # @example
      #   get /api/individual?identifier=String
      # @param [Hash] params { identifier: String }
      # @return [ActionDispatch::Response] {Individual} (see {show})
      def find
        @individual = Individual.find_by(identifier: params[:identifier])
        return head :not_found if @individual.blank?
        render :show
      end

      # @overload index
      #   List individuals
      #   @example
      #     get /api/individuals
      #   @return [ActionDispatch::Response] array of {Individual}
      # @overload index
      #   List product individuals
      #   @example
      #     get /api/products/:product_id/individuals
      #   @param [Hash] params { product_id: Number }
      #   @return [ActionDispatch::Response] array of {Individual}
      #
      #     (See ./app/views/api/v1/individual/index.json.jbuilder)
      #
      #     {include:file:app/views/api/v1/individuals/index.json.jbuilder}
      #
      #     (See ./app/views/api/v1/individual/_individual.json.jbuilder)
      #
      #     {include:file:app/views/api/v1/individuals/_individual.json.jbuilder}
      def index
        @individuals = if params[:product_id].present?
                         set_product
                         @product.individuals
                       else
                         Individual.all
                       end
      end

      # @overload show
      #   Get individual by id
      #   @example
      #     get /api/individual/:id
      #   @param [Hash] params { id: Number }
      #   @return [ActionDispatch::Response] {Individual}
      #
      #     (See ./app/views/api/v1/individual/show.json.jbuilder)
      #
      #     {include:file:app/views/api/v1/individuals/show.json.jbuilder}
      #
      #     (See ./app/views/api/v1/individual/_individual.json.jbuilder)
      #
      #     {include:file:app/views/api/v1/individuals/_individual.json.jbuilder}
      # @overload show
      #   Get product individual
      #   @example
      #     get /api/products/:product_id/individuals/:id
      #   @param [Hash] params { product_id: Number, id: Number }
      #   @return [ActionDispatch::Response]
      def show
        if params[:product_id].present? # rubocop:disable Style/GuardClause
          set_product
          return head :not_found unless @individual.products.include?(@product)
        end
      end

      # Create individual
      # @example
      #   post /api/individuals
      # @param [Hash] params { individual: { identifier: String, name: String, email: String } }
      # @return [ActionDispatch::Response] {Individual} (see {show})
      def create
        @individual = Individual.find_by(identifier: individual_params[:identifier])
        if @individual.present?
          @individual.errors.add(:identifier, "individual identifier #{individual_params[:identifier]} exists!")
          return render json: @individual.errors, status: :unprocessable_entity
        end
        @individual = Individual.new(individual_params)
        return render json: @individual.errors, status: :unprocessable_entity unless @individual.save
        render :show, status: :created, location: @individual
      end

      # @overload update
      #   Update individual
      #   @example
      #     put /api/individuals/:id
      #   @param [Hash] params { id: Number, individual: { name: String, email: String } }
      #   @return [ActionDispatch::Response] {Individual} (see {show})
      # @overload update
      #   Grant individual read access to product
      #   @example
      #     put /api/products/:product_id/individuals/:id
      #   @param [Hash] params { product_id: Number, id: Number }
      #   @return [ActionDispatch::Response]
      def update
        if params[:product_id].present?
          set_product
          Greensub.subscribe(@individual, @product)
          return head :ok
        end
        return render json: @individual.errors, status: :unprocessable_entity unless @individual.update(individual_params)
        render :show, status: :ok, location: @individual
      end

      # @overload destroy
      #   Delete individual
      #   @example
      #     delete /api/individuals/:id
      #   @param [Hash] params { id: Number }
      #   @return [ActionDispatch::Response]
      # @overload destroy
      #   Revoke individual read access to product
      #   @example
      #     put /api/products/:product_id/individuals/:id
      #   @param [Hash] params { product_id: Number, id: Number }
      #   @return [ActionDispatch::Response]
      def destroy
        if params[:product_id].present?
          set_product
          Greensub.unsubscribe(@individual, @product)
        else
          return render json: @individual.errors, status: :accepted unless @individual.destroy
        end
        head :ok
      end

      private

        def set_product
          @product = Product.find(params[:product_id])
        end

        def set_individual
          @individual = Individual.find(params[:id])
        end

        def individual_params
          params.require(:individual).permit(:identifier, :name, :email)
        end
    end
  end
end
