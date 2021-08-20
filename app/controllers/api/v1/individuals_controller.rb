# frozen_string_literal: true

module API
  module V1
    # Individuals Controller
    class IndividualsController < API::ApplicationController
      before_action :set_individual, only: %i[show update destroy license]
      before_action :set_product, only: %i[license]

      # Get individual by identifier
      # @example
      #   get /api/individual?identifier=String
      # @param [Hash] params { identifier: String }
      # @return [ActionDispatch::Response] {Greensub::Individual} (see {show})
      def find
        @individual = Greensub::Individual.find_by(identifier: params[:identifier])
        return head :not_found if @individual.blank?
        render :show
      end

      # @overload index
      #   List individuals
      #   @example
      #     get /api/individuals
      #   @return [ActionDispatch::Response] array of {Greensub::Individual}
      # @overload index
      #   List product individuals
      #   @example
      #     get /api/products/:product_id/individuals
      #   @param [Hash] params { product_id: Number }
      #   @return [ActionDispatch::Response] array of {Greensub::Individual}
      #
      #     (See ./app/views/api/v1/individuals/index.json.jbuilder)
      #
      #     {include:file:app/views/api/v1/individuals/index.json.jbuilder}
      #
      #     (See ./app/views/api/v1/individuals/_individual.json.jbuilder)
      #
      #     {include:file:app/views/api/v1/individuals/_individual.json.jbuilder}
      def index
        @individuals = if params[:product_id].present?
                         set_product
                         @product.individuals
                       else
                         Greensub::Individual.all
                       end
      end

      # @overload show
      #   Get individual by id
      #   @example
      #     get /api/individual/:id
      #   @param [Hash] params { id: Number }
      #   @return [ActionDispatch::Response] {Greensub::Individual}
      #
      #     (See ./app/views/api/v1/individuals/show.json.jbuilder)
      #
      #     {include:file:app/views/api/v1/individuals/show.json.jbuilder}
      #
      #     (See ./app/views/api/v1/individuals/_individual.json.jbuilder)
      #
      #     {include:file:app/views/api/v1/individuals/_individual.json.jbuilder}
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
      # @return [ActionDispatch::Response] {Greensub::Individual} (see {show})
      def create
        @individual = Greensub::Individual.find_by(identifier: individual_params[:identifier])
        if @individual.present?
          @individual.errors.add(:identifier, "individual identifier #{individual_params[:identifier]} exists!")
          return render json: @individual.errors, status: :unprocessable_entity
        end
        @individual = Greensub::Individual.new(individual_params)
        begin
          @individual.save!
        rescue StandardError => e
          @individual.errors.add(:exception, e.to_s)
          return render json: @individual.errors, status: :unprocessable_entity
        end
        render :show, status: :created, location: @individual
      end

      # @overload update
      #   Update individual
      #   @example
      #     put /api/individuals/:id
      #   @param [Hash] params { id: Number, individual: { name: String, email: String } }
      #   @return [ActionDispatch::Response] {Greensub::Individual} (see {show})
      def update
        return render json: @individual.errors, status: :unprocessable_entity unless @individual.update(individual_params)
        render :show, status: :ok, location: @individual
      end

      # @overload destroy
      #   Delete individual
      #   @example
      #     delete /api/individuals/:id
      #   @param [Hash] params { id: Number }
      #   @return [ActionDispatch::Response]
      def destroy
        return render json: @individual.errors, status: :accepted unless @individual.destroy
        head :ok
      end

      # @overload license
      #   Get Product License
      #   @example
      #     get /api/products/:product_id/individuals/:id/license
      #   @param [Hash] params { product_id: Number, id: Number }
      #   @return [ActionDispatch::Response] { String }
      # @overload license
      #   Create Product License
      #   @example
      #     post /api/products/:product_id/individuals/:id/license
      #   @param [Hash] params { product_id: Number, id: Number, license: { type: String } }
      #   @return [ActionDispatch::Response] { String }
      # @overload license
      #   Delete Product License
      #   @example
      #     delete /api/products/:product_id/individuals/:id/license
      #   @param [Hash] params { product_id: Number, id: Number }
      #   @return [ActionDispatch::Response] { String }      #
      #     (See ./app/views/api/v1/individuals/license.json.jbuilder)
      #
      #     {include:file:app/views/api/v1/individuals/license.json.jbuilder}
      def license # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        if request.get?
          pl = @individual.find_product_license(@product)
          return render partial: '/api/v1/licenses/license', locals: { license: pl }, status: :ok if pl.present?
          render json: {}, status: :not_found
        elsif request.post?
          pl = @individual.create_product_license(@product, type: params[:license][:type])
          return render partial: '/api/v1/licenses/license', locals: { license: pl }, status: :ok if pl.present?
          render json: {}, status: :unprocessable_entity
        elsif request.delete?
          pl = @individual.delete_product_license(@product)
          return render partial: '/api/v1/licenses/license', locals: { license: pl }, status: :ok if pl.present?
          head :ok
        end
      rescue StandardError => e
        render json: { exception: e.to_s }, status: :unprocessable_entity
      end

      private

        def set_product
          @product = Greensub::Product.find(params[:product_id])
        end

        def set_individual
          @individual = Greensub::Individual.find(params[:id])
        end

        def individual_params
          params.require(:individual).permit(:identifier, :name, :email)
        end

        def license_params
          params.require(:license).permit(:type)
        end
    end
  end
end
