# frozen_string_literal: true

module API
  module V1
    class IndividualsController < API::ApplicationController
      before_action :set_individual, only: %i[show update destroy]

      # @example get /api/individual?identifer=String
      # @param [Hash] params { identifer: String }
      # @return [ActionDispatch::Response] {Individual}
      #   (See ./app/views/api/v1/individuals/show.json.jbuilder for details)
      def find
        @individual = Individual.find_by(identifier: params[:identifier])
        return head :not_found if @individual.blank?
        render :show
      end

      # @overload index
      #   @example get /api/individuals
      # @return [ActionDispatch::Response] array of {Individual}
      #   (See ./app/views/api/v1/individual/index.json.jbuilder for details)
      def index
        @individuals = Individual.all
      end

      # @overload show
      #   @example get /api/individual/:id
      #   @param [Hash] params { id: Number }
      # @return [ActionDispatch::Response] {Individual}
      #   (See ./app/views/api/v1/individuals/show.json.jbuilder for details)
      def show
        return head :not_found if @individual.blank?
      end

      # @overload create
      #   post /api/individuals
      #   @param [Hash] params { individual: { identifier: String, name: String, email: String } }
      # @return [ActionDispatch::Response] {Individual}
      #   (See ./app/views/api/v1/individual/show.json.jbuilder for details)
      def create
        status = :ok
        @individual = Individual.find_by(identifier: individual_params[:identifier])
        if @individual.blank?
          @individual = Individual.new(individual_params)
          return render json: @individual.errors, status: :unprocessable_entity unless @individual.save
          status = :created
        end
        render :show, status: status, location: @individual
      end

      # @overload update
      #   @example put /api/individuals/:id
      #   @param [Hash] params { id: Number, individual: { name: String, email: String }}
      # @return [ActionDispatch::Response] {Individual}
      #   (See ./app/views/api/v1/individual/show.json.jbuilder for details)
      def update
        return head :not_found if @individual.blank?
        return render json: @individual.errors, status: :unprocessable_entity unless @individual.update(individual_params)
        render :show, status: :ok, location: @individual
      end

      # @overload destroy
      #   @example delete /api/individuals/:id
      #   @param [Hash] params { id: Number }
      # @return [ActionDispatch::Response]
      def destroy
        return head :ok if @individual.blank?
        @individual.destroy
        head :ok
      end

      private

        def set_individual
          @individual = Individual.find_by(id: params[:id])
        end

        # Never trust parameters from the scary internet, only allow the white list through.
        def individual_params
          params.require(:individual).permit(:identifier, :name, :email)
        end
    end
  end
end
