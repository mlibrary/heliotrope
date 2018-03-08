# frozen_string_literal: true

class WebglsController < ApplicationController
  protect_from_forgery except: :file

  def show
    # This isn't actually used right now. Instead we're using what's in views/webgl/_tabs.html.erb which
    # is called from the monograph_catalog page instead of calling this directly
    # through a route. TODO: delete this (and specs), or leave it here as an example?
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
    # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept-Encoding
    accept_headers = request.headers['Accept-Encoding'] || ""
    send_compressed = if accept_headers.include? 'gzip'
                        true
                      else
                        false
                      end
    render plain: FactoryService.webgl_unity(params[:id]).read(params[:file] + "." + params[:format], send_compressed), content_type: Mime::Type.lookup_by_extension(params[:format]), layout: false
  rescue StandardError => e
    Rails.logger.info("WebglsController.file(#{params[:file] + '.' + params[:format]}) mapping to 'Content-Type': #{Mime::Type.lookup_by_extension(params[:format])} raised #{e}")
    head :no_content, status: :not_found
  end
end
