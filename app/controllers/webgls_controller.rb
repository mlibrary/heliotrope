# frozen_string_literal: true

class WebglsController < ApplicationController
  protect_from_forgery except: :file

  def show
    # This isn't actually used right now. Instead we're using what's in views/webgl/_tabs.html.erb which is called
    # from the monograph_catalog page instead of calling this directly through a route. However it's a good place to
    # check the WebGL outside of the EPUB or navigation tab craziness, yet inside Rails and Turbolinks craziness.
    # Eventually we could delete this (and specs), or leave it here "forever" as an example?
    @presenter = Hyrax::PresenterFactory.build_for(ids: [params[:id]], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil).first
    if @presenter.present? && @presenter.webgl?
      webgl = FactoryService.webgl_unity(params[:id])
      @unity_progress = "#{params[:id]}/#{webgl.unity_progress}"
      @unity_loader = "#{params[:id]}/#{webgl.unity_loader}"
      @unity_json = "#{params[:id]}/#{webgl.unity_json}"
      render layout: false
    else
      Rails.logger.info("WebglsController.show(#{params[:id]}) is not a WebGL.")
      render 'hyrax/base/unauthorized', status: :unauthorized
    end
  end

  def file
    # `.unityweb` files are gzipped by default as part of the release build process.
    # They need `Content-Encoding: gzip` to trigger browser unpacking.
    response.headers['Content-Encoding'] = 'gzip' if params[:format] == 'unityweb'

    file = Rails.root + FactoryService.webgl_unity(params[:id]).file(params[:file] + "." + params[:format])
    # Need to match apache's XSendFilePath configuration
    file = file.to_s.sub(/releases\/\d+/, "current")
    response.headers['X-Sendfile'] = file
    send_file file
  rescue StandardError => e
    Rails.logger.info("WebglsController.file(#{params[:file] + '.' + params[:format]}) raised #{e}")
    head :no_content, status: :not_found
  end
end
