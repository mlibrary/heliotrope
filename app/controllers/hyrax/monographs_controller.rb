# frozen_string_literal: true

module Hyrax
  class MonographsController < ApplicationController
    include Hyrax::WorksControllerBehavior
    self.curation_concern_type = ::Monograph
    self.show_presenter = Hyrax::MonographPresenter

    skip_authorize_resource only: %i[create new]
    before_action :authorize_press, only: [:create]
    before_action :authorize_press_admin, only: [:new]

    def publish
      PublishJob.perform_later(curation_concern)
      redirect_to [main_app, curation_concern], notice: 'Monograph is publishing.'
    end

    def reindex
      UpdateIndexJob.perform_later(curation_concern.id)
      redirect_to [main_app, curation_concern], notice: I18n.t('monograph_catalog.index.reindexing', title: curation_concern.title&.first)
    end

    def new
      super
      @form[:press] = params[:press] unless params[:press].nil?
    end

    def show
      if current_ability&.can?(:edit, params[:id])
        super
      else
        redirect_to main_app.monograph_catalog_path(params[:id])
      end
    end

    protected

      # The curation_concerns gem doesn't allow cancancan to
      # populate the monograph with the params because it uses an
      # actor to build the monograph instead.  See here:
      # https://github.com/projecthydra-labs/curation_concerns/blob/master/lib/curation_concerns/controller_resource.rb#L5-L8
      #
      # Because of that, the normal load_and_authorize_resource
      # behavior from cancancan doesn't work because the authorize!
      # method gets called on an empty monograph, but in order to
      # authorize, we need to know which press the user is trying
      # to create a monograph for.
      def authorize_press
        curation_concern.press = params[:monograph][:press]
        authorize!(:create, curation_concern)
      end

      def authorize_press_admin
        raise CanCan::AccessDenied unless current_ability.current_user.platform_admin? || current_ability.current_user.admin_presses.any?
      end
  end
end
