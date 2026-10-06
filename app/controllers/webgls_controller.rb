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
    return head :no_content, status: :not_found unless authorize_file_access?

    filepath = UnpackService.root_path_from_noid(params[:id], 'webgl')
    webgl = Webgl::Unity.from_directory(filepath)
    base_dir = webgl.root_path.presence || filepath

    validated_file = UnpackService.safe_path(base_dir, "#{params[:file]}.#{params[:format]}")
    return head :no_content, status: :not_found if validated_file.blank?
    return head :no_content, status: :not_found unless validated_file.start_with?(File.realpath(base_dir) + File::SEPARATOR)

    # Validate the real path, but preserve the symlink path Apache expects for X-Sendfile.
    relative_file = Pathname(validated_file).relative_path_from(Pathname(File.realpath(base_dir)))
    file = File.join(base_dir.to_s, relative_file.to_s)

    file_stat = File.stat(file)

    # Need to match apache's XSendFilePath configuration
    file = file.to_s.sub(/releases\/\d+/, "current")
    response.headers['X-Sendfile'] = file

    if params[:format] == 'wasm'
      send_file(file, type: 'application/wasm')
    else
      send_file file
    end

    # Keep the origin response immediately revalidatable. The Cloudflare /webgl cache rule can override this for clients
    response.headers['Cache-Control'] = 'public, max-age=0, must-revalidate'
    response.headers['Accept-Ranges'] = 'bytes'
    response.headers['Last-Modified'] = file_stat.mtime.httpdate
    response.headers['ETag'] = %(W/"#{file_stat.size}-#{file_stat.mtime.to_f}")
  rescue StandardError => e
    Rails.logger.info("WebglsController.file(#{params[:file] + '.' + params[:format]}) raised #{e} #{e.backtrace.join("\n")}")
    head :no_content, status: :not_found
  end

  private

    def authorize_file_access?
      return false unless ValidationService.valid_noid?(params[:id])

      entity = Sighrax.from_noid(params[:id])
      return false unless entity.valid?
      return false if entity.tombstone?

      return true if entity.published? || entity.parent.published?
      return true if current_ability.can?(:read, params[:id])
      return true if FeaturedRepresentative.where(file_set_id: params[:id]).any?

      false
    end
end
