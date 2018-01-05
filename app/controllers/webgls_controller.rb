# frozen_string_literal: true

class WebglsController < ApplicationController
  protect_from_forgery except: :file

  def show
    # @presenter = Hyrax::PresenterFactory.build_for(ids: [params[:id]], presenter_class: Hyrax::FileSetPresenter, presenter_args: current_ability)&.first
    @presenter = Hyrax::FileSetPresenter.new(SolrDocument.new(FileSet.find(params[:id]).to_solr), current_ability, request)
    if @presenter.webgl?
      webgl = FactoryService.webgl_unity(params[:id])
      @unity_progress = "#{params[:id]}/#{webgl.unity_progress}"
      @unity_loader = "#{params[:id]}/#{webgl.unity_loader}"
      @unity_json = "#{params[:id]}/#{webgl.unity_json}"
      render layout: false
    else
      Rails.logger.info("WebglsController.show(#{params[:id]}) is not a WebGL.")
      render 'hyrax/base/unauthorized', status: :unauthorized
    end
  rescue Ldp::Gone # tombstone
    raise CanCan::AccessDenied
  end

  def file
    render plain: FactoryService.webgl_unity(params[:id]).read(params[:file] + "." + params[:format]), content_type: Mime::Type.lookup_by_extension(params[:format]), layout: false
  rescue StandardError => e
    Rails.logger.info("WebglsController.file(#{params[:file] + '.' + params[:format]}) mapping to 'Content-Type': #{Mime::Type.lookup_by_extension(params[:format])} raised #{e}")
    head :no_content, status: :not_found
  end
end
