# frozen_string_literal: true

class JsappsController < ApplicationController
  protect_from_forgery except: :file

  def file
    return head :no_content unless authorize_file_access?

    filepath = UnpackService.root_path_from_noid(params[:id], 'interactive_application')
    filename = UnpackService.safe_path(filepath, "#{params[:file]}.#{params[:format]}")
    return head :no_content if filename.blank?

    filename = filename.to_s.sub(/releases\/\d+/, "current")
    response.headers['X-Sendfile'] = filename
    response.headers.except! 'X-Frame-Options'
    send_file filename, disposition: 'inline'
  rescue StandardError => e
    Rails.logger.info("JsappsController.file raised #{e}")
    head :no_content
  end

  private

    def authorize_file_access?
      return false unless ValidationService.valid_noid?(params[:id])

      entity = Sighrax.from_noid(params[:id])
      return true unless entity.valid?
      return false if entity.tombstone?

      return true if entity.published? || entity.parent.published?
      return true if current_ability.can?(:read, params[:id])
      return true if FeaturedRepresentative.where(file_set_id: params[:id]).any?

      false
    end
end
