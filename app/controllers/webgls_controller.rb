# frozen_string_literal: true

class WebglsController < ApplicationController
  protect_from_forgery except: :file

  def show
    # This isn't used for anything public-facing. However it's a good place to check how WebGL is behaving in the...
    # presence of Rails and Turbolinks, yet outside the complexity of CSB and other app components. Escpecially...
    # useful with WebGL files built with newer Unity versions (major version updates).
    # See also https://mlit.atlassian.net/wiki/spaces/FUL/pages/9329476575/WebGL+Representatives
    # Eventually we could delete this (and specs), depending on what happens with future Gabii Monographs.
    #
    # It's the file method below which serves unpacked WebGL files to the EPUB and FileSet page views, located in...
    # `app/views/e_pubs/_webgl_specific.js.erb` and `app/views/hyrax/file_sets/media_display/_webgl.html.erb`,...
    # respectively.
    @presenter = Hyrax::PresenterFactory.build_for(ids: [params[:id]], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil).first
    if @presenter.present? && @presenter.webgl?
      webgl = Webgl::Unity.from_directory(UnpackService.root_path_from_noid(params[:id], 'webgl'))
      @unity_loader = webgl.unity_loader
      @unity_data = webgl.unity_data
      @unity_framework = webgl.unity_framework
      @unity_code = webgl.unity_code
      render layout: false
    else
      Rails.logger.info("WebglsController.show(#{params[:id]}) is not a WebGL.")
      render 'hyrax/base/unauthorized', status: :unauthorized
    end
  end

  def file
    webgl = Webgl::Unity.from_directory(UnpackService.root_path_from_noid(params[:id], 'webgl'))

    file = webgl.file(params[:file] + "." + params[:format])
    file = Rails.root + file if webgl.root_path.blank?

    # Need to match apache's XSendFilePath configuration
    file = file.to_s.sub(/releases\/\d+/, "current")
    response.headers['X-Sendfile'] = file

    if params[:format] == 'wasm'
      send_file(file, type: 'application/wasm')
    else
      send_file file
    end
  rescue StandardError => e
    Rails.logger.info("WebglsController.file(#{params[:file] + '.' + params[:format]}) raised #{e} #{e.backtrace.join("\n")}")
    head :no_content, status: :not_found
  end
end
