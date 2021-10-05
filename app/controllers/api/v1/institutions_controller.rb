# frozen_string_literal: true

module API
  module V1
    # Institutions Controller
    class InstitutionsController < API::ApplicationController
      before_action :set_institution, only: %i[show update destroy license]
      before_action :set_product, only: %i[license]

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
        @institution.display_name = @institution.name if @institution.display_name.blank?
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
      def update
        return render json: @institution.errors, status: :unprocessable_entity unless @institution.update(institution_params)
        render :show, status: :ok, location: @institution
      end

      # @overload destroy
      #   Delete institution
      #   @example
      #     delete /api/institutions/:id
      #   @param [Hash] params { id: Number }
      #   @return [ActionDispatch::Response]
      def destroy
        return render json: @institution.errors, status: :accepted unless @institution.destroy
        head :ok
      end

      # @overload license
      #   Get Product License
      #   @example
      #     get /api/products/:product_id/institutions/:id/license(/:affiliation)
      #   @param [Hash] params { product_id: Number, id: Number }
      #   @return [ActionDispatch::Response] {license}
      # @overload license
      #   Create Product License
      #   @example
      #     post /api/products/:product_id/institutions/:id/license(/:affiliation)
      #   @param [Hash] params { product_id: Number, id: Number, license: String }
      #   @return [ActionDispatch::Response] {license}
      # @overload license
      #   Delete Product License
      #   @example
      #     delete /api/products/:product_id/institutions/:id/license(/:affiliation)
      #   @param [Hash] params { product_id: Number, id: Number }
      #   @return [ActionDispatch::Response]  { String }
      #     (See ./app/views/api/v1/institutions/license.json.jbuilder)
      #
      #     {include:file:app/views/api/v1/institutions/license.json.jbuilder}
      def license # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        if request.get?
          pl = @institution.find_product_license(@product, affiliation: params[:affiliation] || 'member')
          return render partial: '/api/v1/licenses/license', locals: { license: pl }, status: :ok if pl.present?
          render json: {}, status: :not_found
        elsif request.post?
          pl = @institution.create_product_license(@product, type: params[:license][:type], affiliation: params[:affiliation] || 'member')
          return render partial: '/api/v1/licenses/license', locals: { license: pl }, status: :ok if pl.present?
          render json: {}, status: :unprocessable_entity
        elsif request.delete?
          pl = @institution.delete_product_license(@product, affiliation: params[:affiliation] || 'member')
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

        def set_institution
          @institution = Greensub::Institution.find(params[:id])
        end

        def institution_params
          params.require(:institution).permit(:identifier, :name, :display_name, :entity_id, :catalog_url, :link_resolver_url, :location, :login, :logo_path, :ror_id, :site)
        end

        def license_params
          params.require(:license).permit(:type)
        end
    end
  end
end
