# frozen_string_literal: true

module API
  module V1
    class InstitutionsController < API::ApplicationController
      before_action :set_institution, only: %i[show update destroy]

      # @example get /api/institution?identifer=String
      # @param [Hash] params { identifer: String }
      # @return [ActionDispatch::Response] {Institution}
      #   (See ./app/views/api/v1/institutions/show.json.jbuilder for details)
      def find
        @institution = Institution.find_by(identifier: params[:identifier])
        return head :not_found if @institution.blank?
        render :show
      end

      # @overload index
      #   @example get /api/institutions
      # @return [ActionDispatch::Response] array of {Institution}
      #   (See ./app/views/api/v1/institution/index.json.jbuilder for details)
      def index
        @institutions = Institution.all
      end

      # @overload show
      #   @example get /api/institution/:id
      #   @param [Hash] params { id: Number }
      # @return [ActionDispatch::Response] {Institution}
      #   (See ./app/views/api/v1/institutions/show.json.jbuilder for details)
      def show
        return head :not_found if @institution.blank?
      end

      # @overload create
      #   post /api/institutions
      #   @param [Hash] params { institution: { identifier: String, name: String, login: String, site: String, entity_id: String } }
      # @return [ActionDispatch::Response] {Institution}
      #   (See ./app/views/api/v1/institution/show.json.jbuilder for details)
      def create
        status = :ok
        @institution = Institution.find_by(identifier: institution_params[:identifier])
        if @institution.blank?
          @institution = Institution.new(institution_params)
          return render json: @institution.errors, status: :unprocessable_entity unless @institution.save
          status = :created
        end
        render :show, status: status, location: @institution
      end

      # @overload update
      #   @example put /api/institutions/:id
      #   @param [Hash] params { id: Number, institution: { name: String, login: String, site: String, entity_id: String }}
      # @return [ActionDispatch::Response] {Institution}
      #   (See ./app/views/api/v1/institution/show.json.jbuilder for details)
      def update
        return head :not_found if @institution.blank?
        return render json: @institution.errors, status: :unprocessable_entity unless @institution.update(institution_params)
        render :show, status: :ok, location: @institution
      end

      # @overload destroy
      #   @example delete /api/components/:id
      #   @param [Hash] params { id: Number }
      # @return [ActionDispatch::Response]
      def destroy
        return head :ok if @institution.blank?
        @institution.destroy
        head :ok
      end

      private

        def set_institution
          @institution = Institution.find_by(id: params[:id])
        end

        # Never trust parameters from the scary internet, only allow the white list through.
        def institution_params
          params.require(:institution).permit(:name, :site, :login, :identifier, :entity_id)
        end
    end
  end
end
