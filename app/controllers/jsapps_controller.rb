# frozen_string_literal: true

class JsappsController < ApplicationController
  protect_from_forgery except: :file

  def file
    filepath = UnpackService.root_path_from_noid(params[:id], 'interactive_application')
    filename = filepath + '/' + params[:file] + '.' + params[:format]
    filename = filename.to_s.sub(/releases\/\d+/, "current")
    response.headers['X-Sendfile'] = filename
    response.headers.except! 'X-Frame-Options'
    send_file filename, disposition: 'inline'
  rescue StandardError => e
    Rails.logger.info("JsappsController.file#{filename} raised #{e}")
    head :no_content
  end
end
