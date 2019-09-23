# frozen_string_literal: true

module API
  module V1
    # Presses Controller
    class PressesController < API::ApplicationController
      before_action :set_press, only: %i[show]

      # Get press by subdomain
      # @example
      #   get /api/press?subdomain=String
      # @param [Hash] params { subdomain: String }
      # @return [ActionDispatch::Response] {Press} (see {show})
      def find
        @press = Press.find_by(subdomain: params[:subdomain])
        return head :not_found if @press.blank?
        render :show
      end

      # List presses
      # @example
      #   get /api/presses
      # @return [ActionDispatch::Response] array of {Press}
      #
      #   (See ./app/views/api/v1/presses/index.json.jbuilder)
      #
      #   {include:file:app/views/api/v1/presses/index.json.jbuilder}
      #
      #   (See ./app/views/api/v1/presses/_press.json.jbuilder)
      #
      #   {include:file:app/views/api/v1/presses/_press.json.jbuilder}
      def index
        @presses = Press.all
      end

      # Get press by id
      # @example
      #   get /api/presses/:id
      # @param [Hash] params { id: Number }
      # @return [ActionDispatch::Response] {Press}
      #
      #   (See ./app/views/api/v1/presses/show.json.jbuilder)
      #
      #   {include:file:app/views/api/v1/presses/show.json.jbuilder}
      #
      #   (See ./app/views/api/v1/presses/_press.json.jbuilder)
      #
      #   {include:file:app/views/api/v1/presses/_press.json.jbuilder}
      def show; end

      private

        def set_press
          @press = Press.find(params[:id])
        end

        def press_params
          params.require(:press).permit(:subdomain)
        end
    end
  end
end
