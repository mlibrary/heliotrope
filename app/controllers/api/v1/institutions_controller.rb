# frozen_string_literal: true

module API
  module V1
    # Institutions Controller
    class InstitutionsController < API::ApplicationController
      before_action :set_institution, only: %i[show update destroy]

      # Get institution by identifier
      # @example
      #   get /api/institution?identifier=String
      # @param [Hash] params { identifer: String }
      # @return [ActionDispatch::Response] {Institution} (see {show})
      def find
        @institution = Institution.find_by(identifier: params[:identifier])
        return head :not_found if @institution.blank?
        render :show
      end

      # @overload index
      #   List institutions
      #   @example
      #     get /api/institutions
      #   @return [ActionDispatch::Response] array of {Institution}
      # @overload index
      #   List product institutions
      #   @example
      #     get /api/products/:product_id/institutions
      #   @param [Hash] params { product_id: Number }
      #   @return [ActionDispatch::Response] array of {Institution}
      #
      #     (See ./app/views/api/v1/institution/index.json.jbuilder)
      #
      #     {include:file:app/views/api/v1/institutions/index.json.jbuilder}
      #
      #     (See ./app/views/api/v1/institution/_institution.json.jbuilder)
      #
      #     {include:file:app/views/api/v1/institutions/_institution.json.jbuilder}
      def index
        @institutions = if params[:product_id].present?
                          set_product
                          @product.institutions
                        else
                          Institution.all
                        end
      end

      # Get institution by id
      # @example
      #   get /api/institution/:id
      # @param [Hash] params { id: Number }
      # @return [ActionDispatch::Response] {Institution}
      #
      #   (See ./app/views/api/v1/institution/show.json.jbuilder)
      #
      #   {include:file:app/views/api/v1/institutions/show.json.jbuilder}
      #
      #   (See ./app/views/api/v1/institution/_institution.json.jbuilder)
      #
      #   {include:file:app/views/api/v1/institutions/_institution.json.jbuilder}
      def show; end

      # Create institution
      # @example
      #   post /api/institutions
      # @param [Hash] params { institution: { identifier: String, name: String, entity_id: String } }
      # @return [ActionDispatch::Response] {Institution} (see {show})
      def create
        @institution = Institution.find_by(identifier: institution_params[:identifier])
        if @institution.present?
          @institution.errors.add(:identifier, "institution identifier #{institution_params[:identifier]} exists!")
          return render json: @institution.errors, status: :unprocessable_entity
        end
        @institution = Institution.new(institution_params)
        return render json: @institution.errors, status: :unprocessable_entity unless @institution.save
        render :show, status: :created, location: @institution
      end

      # @overload update
      #   Update institution
      #   @example
      #     put /api/institutions/:id
      #   @param [Hash] params { id: Number, institution: { name: String, email: String } }
      #   @return [ActionDispatch::Response] {Institution} (see {show})
      # @overload update
      #   Grant institution read access to product
      #   @example
      #     put /api/products/:product_id/institutions/:id
      #   @param [Hash] params { product_id: Number, id: Number }
      #   @return [ActionDispatch::Response]
      def update
        if params[:product_id].present?
          set_product
          unless @institution.lessee.products.include?(@product)
            @institution.lessee.products << @product
            @institution.save
            PermissionService.permit_read_access_resource(@institution.agent_type, @institution.agent_id, @product.resource_type, @product.resource_id)
          end
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
          if @institution.lessee.products.include?(@product)
            @institution.lessee.products.delete(@product)
            PermissionService.revoke_read_access_resource(@institution.agent_type, @institution.agent_id, @product.resource_type, @product.resource_id)
          end
        else
          return render json: @institution.errors, status: :accepted unless @institution.destroy
        end
        head :ok
      end

      private

        def set_product
          @product = Product.find(params[:product_id])
        end

        def set_institution
          @institution = Institution.find(params[:id])
        end

        def institution_params
          params.require(:institution).permit(:identifier, :name, :entity_id, :site, :login)
        end
    end
  end
end
