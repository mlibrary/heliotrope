# frozen_string_literal: true

class EmbedController < ApplicationController
  delegate :noid, to: :class

  def show
    # Removing any X-Frame-Options header here, to allow embedding in third-party sites, used to work before we started
    # using Cloudflare (to tame the deluge of badly-behaved bots) in Dec 2024. Cloudflare adds this header back in,
    # though, so removing it *in Cloudflare* with a "Response Header Transform Rule" is the best way to go, rather than
    # adding a "Content Security Policy" header here to override it, which kind of makes things worse, and more confusing.
    # Said rule is in place now, and only kicks in when "URI path starts with /embed", so security on other pages is
    # unaffected. For historical context see HELIO-730, HELIO-4792, HELIO-5122.
    # I'll leave the original header-removal line in place below so that heliotrope instances not using Cloudflare
    # will work as they did pre-2024/12.
    response.headers.except! 'X-Frame-Options'

    @presenter = Hyrax::PresenterFactory.build_for(ids: [self.noid(params[:hdl] || "")], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil).first
    if @presenter.nil?
      render 'hyrax/base/unauthorized', status: :unauthorized
    else
      CounterService.from(self, @presenter).count(request: 1)
      render layout: false
    end
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
