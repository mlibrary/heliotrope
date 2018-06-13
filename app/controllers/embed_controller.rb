# frozen_string_literal: true

class EmbedController < ApplicationController
  def show
    response.headers.except! 'X-Frame-Options'
    noid = HandleService.noid(params[:hdl] || "")
    @presenter = Hyrax::PresenterFactory.build_for(ids: [noid], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil).first
    if @presenter.nil?
      render 'hyrax/base/unauthorized', status: :unauthorized
    else
      render layout: false
    end
  end
end
