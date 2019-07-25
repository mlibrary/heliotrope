# frozen_string_literal: true

class MapsController < ApplicationController
  protect_from_forgery except: :file

  def file
    filepath = UnpackService.root_path_from_noid(params[:id], 'map')
    filename = filepath + '/' + params[:file] + '.' + params[:format]
    filename = filename.to_s.sub(/releases\/\d+/, "current")
    response.headers['X-Sendfile'] = filename
    send_file filename, disposition: 'inline'
  rescue StandardError => e
    Rails.logger.info("MapsController.file#{filename} raised #{e}")
    head :no_content
  end
end
