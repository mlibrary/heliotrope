# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work Score`
module Hyrax
  # Generated controller for Score
  class ScoresController < ApplicationController
    # Adds Hyrax behaviors to the controller.
    include Hyrax::WorksControllerBehavior
    include Hyrax::BreadcrumbsForWorks
    self.curation_concern_type = ::Score

    # Use this line if you want to use a custom presenter
    self.show_presenter = Hyrax::ScorePresenter

    skip_authorize_resource only: %i[create new]
    before_action :authorize_press, only: [:create]
    before_action :authorize_press_admin, only: [:new]

    def new
      # Right now only carillon can have Scores
      super
      @form[:press] = Services.score_press
    end

    def show
      if current_ability&.can?(:edit, params[:id])
        super
      else
        redirect_to main_app.score_catalog_path(params[:id])
      end
    end

    private
      def authorize_press
        curation_concern.press = Services.score_press
        authorize!(:create, curation_concern)
      end

      def authorize_press_admin
        raise CanCan::AccessDenied unless current_ability.current_user.platform_admin? || current_ability.current_user.admin_presses.map(&:subdomain).include?(Services.score_press)
      end
  end
end
