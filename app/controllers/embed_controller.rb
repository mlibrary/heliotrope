# frozen_string_literal: true

class EmbedController < ApplicationController
  include IrusAnalytics::Controller::AnalyticsBehaviour

  def show
    response.headers.except! 'X-Frame-Options'
    noid = HandleNet.noid(params[:hdl] || "")
    @presenter = Hyrax::PresenterFactory.build_for(ids: [noid], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil).first
    if @presenter.nil?
      render 'hyrax/base/unauthorized', status: :unauthorized
    else
      CounterService.from(self, @presenter).count(request: 1)
      send_irus_analytics_request
      render layout: false
    end
  end

  # HELIO-4143, HELIO-3778
  def item_identifier_for_irus_analytics
    CatalogController.blacklight_config.oai[:provider][:record_prefix] + ":" + @presenter.parent.id
  end
end
