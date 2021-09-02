# frozen_string_literal: true

module API
  module V1
    # Institution Affiliations Controller
    class InstitutionAffiliationsController < API::ApplicationController
      before_action :set_institution
      before_action :set_institution_affiliation, only: %i[show update]

      # Get institution affiliation by dlps and affiliation
      # @example
      #   get /api/institution/:institution_id/affiliation?dlps_institution_id=Number:affiliation=String
      # @param [Hash] params { dlps_institution_id: Number, affiliation: String }
      # @return [ActionDispatch::Response] {Greensub::InstitutionAffiliation} (see {show})
      def find
        @institution_affiliation = @institution.affiliations.find_by(dlps_institution_id: params[:dlps_institution_id], affiliation: params[:affiliation])
        return head :not_found if @institution_affiliation.blank?
        render :show
      end

      # @overload index
      #   List institution affiliations
      #   @example
      #     get /api/institutions/:institution_id/affiliations
      #   @param [Hash] params { institution_id: Number }
      #   @return [ActionDispatch::Response] array of {Greensub::InstitutionAffiliation}
      #
      #     (See ./app/views/api/v1/institution_affiliation/index.json.jbuilder)
      #
      #     {include:file:app/views/api/v1/institution_affiliations/index.json.jbuilder}
      #
      #     (See ./app/views/api/v1/institution_affiliation/_institution_affiliation.json.jbuilder)
      #
      #     {include:file:app/views/api/v1/institution_affiliations/_institution_affiliation.json.jbuilder}
      def index
        @institution_affiliations = @institution.affiliations
      end

      # @overload show
      #   Get institution affiliation by id
      #   @example
      #     get /api/institution/:institution_id/affiliation/:id
      #   @param [Hash] params { institution_id: Number, id: Number }
      #   @return [ActionDispatch::Response] {Greensub::InstitutionAffiliation}
      #
      #     (See ./app/views/api/v1/institution_affiliation/show.json.jbuilder)
      #
      #     {include:file:app/views/api/v1/institution_affiliations/show.json.jbuilder}
      #
      #     (See ./app/views/api/v1/institution_affiliation/_institution_affiliation.json.jbuilder)
      #
      #     {include:file:app/views/api/v1/institution_affiliations/_institution_affiliation.json.jbuilder}
      def show; end

      # @overload create
      #   Create institution_affiliation
      #   @example
      #     post /api/institution/:institution_id:/affiliations
      #   @param [Hash] params { institution_affiliation: { dlps_institution_id: Number, affiliation: String } }
      #   @return [ActionDispatch::Response] {Greensub::InstitutionAffiliation} (see {show})
      def create
        @institution_affiliation = Greensub::InstitutionAffiliation.new(institution_affiliation_params)
        @institution_affiliation.institution = @institution
        begin
          @institution_affiliation.save!
        rescue StandardError => e
          @institution_affiliation.errors.add(:exception, e.to_s)
          return render json: @institution_affiliation.errors, status: :unprocessable_entity
        end
        render :show, status: :created, location: @institution_affiliation
      end

      # @overload update
      #   Update institution affiliation
      #   @example
      #     put /api/institutions/:institution_id/affiliations/:id
      #   @param [Hash] params { dlps_institution_id: Number, affiliation: String }
      #   @return [ActionDispatch::Response]
      def update
        if @institution_affiliation.institution_id != @institution.id
          @institution_affiliation.errors.add(:institution_id, "institution affiliation institution_id '#{@institution_affiliation.institution_id}' does not match institution id '#{@institution.id}'")
          return render json: @institution_affiliation.errors, status: :unprocessable_entity
        end
        return render json: @institution_affiliation.errors, status: :unprocessable_entity unless @institution_affiliation.update(institution_affiliation_params)
        render :show, status: :ok, location: @institution_affiliation
      end

      # @overload destroy
      #   Delete institution affiliation
      #   @example
      #     delete /api/institutions/:institution_id/affiliations/:id
      #   @param [Hash] params { institution_id: Number, id: Number }
      #   @return [ActionDispatch::Response]
      def destroy
        set_institution_affiliation
        if @institution_affiliation.institution_id != @institution.id
          @institution_affiliation.errors.add(:institution_id, "institution affiliation institution_id '#{@institution_affiliation.institution_id}' does not match institution id '#{@institution.id}'")
          return render json: @institution_affiliation.errors, status: :unprocessable_entity
        else
          return render json: @institution_affiliation.errors, status: :accepted unless @institution_affiliation.destroy
        end
        head :ok
      rescue
        head :ok
      end

      private

        def set_institution
          @institution = Greensub::Institution.find(params[:institution_id])
        end

        def set_institution_affiliation
          @institution_affiliation = Greensub::InstitutionAffiliation.find(params[:id])
        end

        def institution_affiliation_params
          params.require(:institution_affiliation).permit(:dlps_institution_id, :affiliation)
        end
    end
  end
end
