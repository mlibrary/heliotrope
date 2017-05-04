# frozen_string_literal: true

class EmbedController < ApplicationController
  def show
    response.headers.except! 'X-Frame-Options'
    hdl = params[:hdl]
    object = hdl.nil? ? nil : HandleService.object(hdl)
    @presenter = object.nil? ? nil : CurationConcerns::PresenterFactory.build_presenters([object.id], CurationConcerns::FileSetPresenter, current_ability).first
    if @presenter.nil?
      render 'curation_concerns/base/unauthorized', status: :unauthorized
    else
      render layout: false
    end
  end
end
