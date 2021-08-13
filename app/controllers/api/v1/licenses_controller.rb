# frozen_string_literal: true

module API
  module V1
    # Licenses Controller
    class LicensesController < API::ApplicationController
      before_action :set_license, only: %i[show update destroy]

      # @overload index
      #   List licenses
      #   @example
      #     get /api/licenses
      #   @return [ActionDispatch::Response] array of {Greensub::License}
      # @overload index
      #   List product licenses
      #   @example
      #     get /api/products/:product_id/licenses
      #   @param [Hash] params { product_id: Number }
      #   @return [ActionDispatch::Response] array of {Greensub::License}
      # @overload index
      #   List individual licenses
      #   @example
      #     get /api/individual/:individual_id/licenses
      #   @param [Hash] params { individual_id: Number }
      #   @return [ActionDispatch::Response] array of {Greensub::License}
      # @overload index
      #   List institution licenses
      #   @example
      #     get /api/institution/:instituion_id/licenses
      #   @param [Hash] params { instituion_id: Number }
      #   @return [ActionDispatch::Response] array of {Greensub::License}
      #
      #     (See ./app/views/api/v1/license/index.json.jbuilder)
      #
      #     {include:file:app/views/api/v1/licenses/index.json.jbuilder}
      #
      #     (See ./app/views/api/v1/license/_license.json.jbuilder)
      #
      #     {include:file:app/views/api/v1/licenses/_license.json.jbuilder}
      def index
        @licenses = if params[:product_id].present?
                      set_product
                      @product.licenses
                    elsif params[:individual_id].present?
                      set_individual
                      @individual.licenses
                    elsif params[:institution_id].present?
                      set_institution
                      @institution.licenses
                    else
                      Greensub::License.all
                    end
      end

      # Get license by id
      # @example
      #   get /api/license/:id
      # @param [Hash] params { id: Number }
      # @return [ActionDispatch::Response] {Greensub::License}
      #
      #   (See ./app/views/api/v1/license/show.json.jbuilder)
      #
      #   {include:file:app/views/api/v1/licenses/show.json.jbuilder}
      #
      #   (See ./app/views/api/v1/license/_license.json.jbuilder)
      #
      #   {include:file:app/views/api/v1/licenses/_license.json.jbuilder}
      def show; end

      # Create license
      # @example
      #   post /api/licenses
      # @param [Hash] params { license: { type: String, licensee_type: String, licensee_id: Number, product_id: Number } }
      # @return [ActionDispatch::Response] {Greensub::License} (see {show})
      def create
        @license = Greensub::License.find_by(license_params)
        return render :show, status: :created, location: api_license_url(@license) if @license.present?

        @license = Greensub::License.new(license_params)
        begin
          @license.save!
        rescue StandardError => e
          @license.errors.add(:exception, e.to_s)
          return render json: @license.errors, status: :unprocessable_entity
        end
        render :show, status: :created, location: api_license_url(@license)
      end

      # Update license
      # @example
      #   put /api/licenses/:id
      # @param [Hash] params { id: Number, license: { name: String, purchase: String } }
      # @return [ActionDispatch::Response] {Greensub::License} (see {show})
      def update
        return render json: @license.errors, status: :unprocessable_entity unless @license.update(license_params)
        render :show, status: :ok, location: api_license_url(@license)
      end

      # Delete license
      # @example
      #   delete /api/licenses/:id
      # @param [Hash] params { id: Number }
      # @return [ActionDispatch::Response]
      def destroy
        return render json: @license.errors, status: :accepted unless @license.destroy
        head :ok
      end

      private

        def set_product
          @product = Greensub::Product.find(params[:product_id])
        end

        def set_individual
          @individual = Greensub::Individual.find(params[:individual_id])
        end

        def set_institution
          @institution = Greensub::Institution.find(params[:institution_id])
        end

        def set_license
          @license = Greensub::License.find(params[:id])
        end

        def license_params
          params.require(:license).permit(:type, :licensee_type, :licensee_id, :product_id)
        end
    end
  end
end
