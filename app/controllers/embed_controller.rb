# frozen_string_literal: true

class EmbedController < ApplicationController
  include IrusAnalytics::Controller::AnalyticsBehaviour
  delegate :noid, to: :class

  def show
    response.headers.except! 'X-Frame-Options'
    # See HELIO-4792
    # By default, Cloudflare is adding "X-Frame-Options: SAMEORIGIN" to all responses regardless of that
    # header's removal above. We want anyone to be able to embed in an iframe, but we'd like to keep the Cloudflare default
    # for the rest of Fulcrum so adding an explicit Content-Security-Policy header for only the /embed route which
    # should take precident over any X-Frame-Options
    response.set_header("Content-Security-Policy", "frame-ancestors 'self' *")
    @presenter = Hyrax::PresenterFactory.build_for(ids: [self.noid(params[:hdl] || "")], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil).first
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

  def self.noid(handle_path_or_url)
    match = /^(#{Regexp.escape(HandleNet::HANDLE_NET_PREFIX)})?(#{Regexp.escape('2027/fulcrum.')})(.*)$/i.match(handle_path_or_url || "")
    return nil if match.nil?
    noid = /^[[:alnum:]]{9}$/i.match(match[3])
    return match[3] unless noid.nil?
    noid = /^([[:alnum:]]{9})\?(.*)$/i.match(match[3])
    return nil if noid.nil?
    noid[1]
  end
end
