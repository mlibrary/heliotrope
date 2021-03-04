# frozen_string_literal: true

module API
  module V1
    # Institutions Controller
    class InstitutionsController < API::ApplicationController
      before_action :set_institution, only: %i[show update destroy access]
      before_action :set_product, only: %i[access]

      # Get institution by identifier
      # @example
      #   get /api/institution?identifier=String
      # @param [Hash] params { identifier: String }
      # @return [ActionDispatch::Response] {Greensub::Institution} (see {show})
      def find
        @institution = Greensub::Institution.find_by(identifier: params[:identifier])
        return head :not_found if @institution.blank?
        render :show
      end

      # @overload index
      #   List institutions
      #   @example
      #     get /api/institutions
      #   @return [ActionDispatch::Response] array of {Greensub::Institution}
      # @overload index
      #   List product institutions
      #   @example
      #     get /api/products/:product_id/institutions
      #   @param [Hash] params { product_id: Number }
      #   @return [ActionDispatch::Response] array of {Greensub::Institution}
      #
      #     (See ./app/views/api/v1/institutions/index.json.jbuilder)
      #
      #     {include:file:app/views/api/v1/institutions/index.json.jbuilder}
      #
      #     (See ./app/views/api/v1/institutions/_institution.json.jbuilder)
      #
      #     {include:file:app/views/api/v1/institutions/_institution.json.jbuilder}
      def index
        @institutions = if params[:product_id].present?
                          set_product
                          @product.institutions
                        else
                          Greensub::Institution.all
                        end
      end

      # @overload show
      #   Get institution by id
      #   @example
      #     get /api/institution/:id
      #   @param [Hash] params { id: Number }
      #   @return [ActionDispatch::Response] {Greensub::Institution}
      #
      #     (See ./app/views/api/v1/institutions/show.json.jbuilder)
      #
      #     {include:file:app/views/api/v1/institutions/show.json.jbuilder}
      #
      #     (See ./app/views/api/v1/institutions/_institution.json.jbuilder)
      #
      #     {include:file:app/views/api/v1/institutions/_institution.json.jbuilder}
      # @overload show
      #   Get product institution
      #   @example
      #     get /api/products/:product_id/institutions/:id
      #   @param [Hash] params { product_id: Number, id: Number }
      #   @return [ActionDispatch::Response]
      def show
        if params[:product_id].present? # rubocop:disable Style/GuardClause
          set_product
          return head :not_found unless @institution.products.include?(@product)
        end
      end

      # Create institution
      # @example
      #   post /api/institutions
      # @param [Hash] params { institution: { identifier: String, name: String, entity_id: String } }
      # @return [ActionDispatch::Response] {Greensub::Institution} (see {show})
      def create
        @institution = Greensub::Institution.find_by(identifier: institution_params[:identifier])
        if @institution.present?
          @institution.errors.add(:identifier, "institution identifier #{institution_params[:identifier]} exists!")
          return render json: @institution.errors, status: :unprocessable_entity
        end
        @institution = Greensub::Institution.new(institution_params)
        begin
          @institution.save!
        rescue StandardError => e
          @institution.errors.add(:exception, e.to_s)
          return render json: @institution.errors, status: :unprocessable_entity
        end
        render :show, status: :created, location: @institution
      end

      # @overload update
      #   Update institution
      #   @example
      #     put /api/institutions/:id
      #   @param [Hash] params { id: Number, institution: { name: String, email: String } }
      #   @return [ActionDispatch::Response] {Greensub::Institution} (see {show})
      # @overload update
      #   Grant institution read access to product
      #   @example
      #     put /api/products/:product_id/institutions/:id
      #   @param [Hash] params { product_id: Number, id: Number }
      #   @return [ActionDispatch::Response]
      def update
        if params[:product_id].present?
          set_product
          @institution.update_product_license(@product)
          return head :ok # rubocop:disable Style/RedundantReturn
        else
          return render json: @institution.errors, status: :unprocessable_entity unless @institution.update(institution_params)
          render :show, status: :ok, location: @institution
        end
      end

      # @overload destroy
      #   Delete institution
      #   @example
      #     delete /api/institutions/:id
      #   @param [Hash] params { id: Number }
      #   @return [ActionDispatch::Response]
      # @overload destroy
      #   Revoke institution read access to product
      #   @example
      #     put /api/products/:product_id/institutions/:id
      #   @param [Hash] params { product_id: Number, id: Number }
      #   @return [ActionDispatch::Response]
      def destroy
        if params[:product_id].present?
          set_product
          @institution.delete_product_license(@product)
        else
          return render json: @institution.errors, status: :accepted unless @institution.destroy
        end
        head :ok
      end

      # @overload access
      #   Get product access
      #   @example
      #     get /api/products/:product_id/institutions/:id/access
      #   @param [Hash] params { product_id: Number, id: Number }
      #   @return [ActionDispatch::Response] {access}
      # @overload access
      #   Set product access
      #   @example
      #     post /api/products/:product_id/institutions/:id/access
      #   @param [Hash] params { product_id: Number, id: Number, access: String }
      #   @return [ActionDispatch::Response] {access}
      #
      #     (See ./app/views/api/v1/institutions/access.json.jbuilder)
      #
      #     {include:file:app/views/api/v1/institutions/access.json.jbuilder}
      def access
        return render json: { "access" => "undefined" }, status: :accepted unless @institution.products.include?(@product)

        if params[:access].present?
        end
      end

      private

        def set_product
          @product = Greensub::Product.find(params[:product_id])
        end

        def set_institution
          @institution = Greensub::Institution.find(params[:id])
        end

        def institution_params
          params.require(:institution).permit(:identifier, :name, :entity_id, :site, :login)
        end
    end
  end
end
