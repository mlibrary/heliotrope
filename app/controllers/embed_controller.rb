# frozen_string_literal: true

class EmbedController < ApplicationController
  def show
    response.headers.except! 'X-Frame-Options'
    hdl = params[:hdl]
    object = hdl.nil? ? nil : HandleService.object(hdl)
    @presenter = object.nil? ? nil : Hyrax::PresenterFactory.build_presenters([object.id], Hyrax::FileSetPresenter, current_ability).first
    if @presenter.nil?
      render 'hyrax/base/unauthorized', status: :unauthorized
    else
      render layout: false
    end
  rescue Ldp::Gone # tombstone
    raise CanCan::AccessDenied
  end
end
