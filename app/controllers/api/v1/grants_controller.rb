# frozen_string_literal: true

module API
  module V1
    # Grants Controller
    class GrantsController < API::ApplicationController
      before_action :set_grant, only: %i[show destroy]

      # Get grant
      # @example
      #   get /api/grant?agent=String;credential=String;resource=String
      # @param [Hash] params { agent: String, credential: String, resource: String }
      # @return [ActionDispatch::Response] {Grant} (see {show})
      def find
        @grant = Grant.find_by(agent_token: params[:agent], credential_token: params[:credential], resource_token: params[:resource])
        return head :not_found if @grant.blank?
        render :show
      end

      # @overload index
      #   List grants
      #   @example
      #     get /api/grants
      #   @return [ActionDispatch::Response] array of {Grant}
      # @overload index
      #   List product grants
      #   @example
      #     get /api/products/:product_id/grants
      #   @param [Hash] params { product_id: Number }
      #   @return [ActionDispatch::Response] array of {Grant}
      # @overload index
      #   List individual grants
      #   @example
      #     get /api/individual/:individual_id/grants
      #   @param [Hash] params { individual_id: Number }
      #   @return [ActionDispatch::Response] array of {Grant}
      # @overload index
      #   List institution grants
      #   @example
      #     get /api/institution/:instituion_id/grants
      #   @param [Hash] params { instituion_id: Number }
      #   @return [ActionDispatch::Response] array of {Grant}
      #
      #     (See ./app/views/api/v1/grant/index.json.jbuilder)
      #
      #     {include:file:app/views/api/v1/grants/index.json.jbuilder}
      #
      #     (See ./app/views/api/v1/grant/_grant.json.jbuilder)
      #
      #     {include:file:app/views/api/v1/grants/_grant.json.jbuilder}
      def index
        @grants = []
        if params[:product_id].present?
          set_product
          @grants = @product.grants
        elsif params[:individual_id].present?
          set_individual
          @grants = @individual.grants
        elsif params[:institution_id].present?
          set_institution
          @grants = @institution.grants
        else
          permits = Checkpoint::DB::Permit.all
          @grants = permits.map { |permit| Grant.new(permit) }
        end
      end

      # Get grant by id
      # @example
      #   get /api/grant/:id
      # @param [Hash] params { id: Number }
      # @return [ActionDispatch::Response] {Grant}
      #
      #   (See ./app/views/api/v1/grant/show.json.jbuilder)
      #
      #   {include:file:app/views/api/v1/grants/show.json.jbuilder}
      #
      #   (See ./app/views/api/v1/grant/_grant.json.jbuilder)
      #
      #   {include:file:app/views/api/v1/grants/_grant.json.jbuilder}
      def show; end

      # Create grant
      # @example
      #   post /api/grants
      # @param [Hash] params { grant: { agent_type: String, agent_id: String, agent_token: String,
      #   credential_type: String, credential_id: String, credential_token: String,
      #   resource_type: String, resource_id: String, resource_token: String,
      #   zone_id: String } }
      # @return [ActionDispatch::Response] {Grant} (see {show})
      def create
        @grant = Grant.new
        @grant.set(grant_params)
        unique = @grant.unique
        if unique.present?
          @grant = unique
          return render :show, status: :ok, location: @grant
        end
        return render json: @grant.errors, status: :unprocessable_entity unless @grant.save
        render :show, status: :created, location: @grant
      end

      # Delete grant
      # @example
      #   delete /api/grants/:id
      # @param [Hash] params { id: Number }
      # @return [ActionDispatch::Response]
      def destroy
        return head :ok if @grant.blank?
        @grant.destroy
        head :ok
      end

      private

        def set_product
          @product = Product.find(params[:product_id])
        end

        def set_individual
          @individual = Individual.find(params[:individual_id])
        end

        def set_institution
          @institution = Institution.find(params[:institution_id])
        end

        def set_grant
          permit = Checkpoint::DB::Permit.find(id: params[:id])
          raise(ActiveRecord::RecordNotFound, "Couldn't find Grant") if permit.blank?
          @grant = Grant.new(permit)
        end

        def grant_params
          params.require(:grant).permit(
            :agent_type, :agent_id, :agent_token,
            :credential_type, :credential_id, :credential_token,
            :resource_type, :resource_id, :resource_token,
            :zone_id
          )
        end
    end
  end
end
