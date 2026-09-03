# frozen_string_literal: true

class JsappsController < ApplicationController
  protect_from_forgery except: :file

  def file
    return head :no_content unless authorize_file_access?

    filepath = UnpackService.root_path_from_noid(params[:id], 'interactive_application')
    filename = UnpackService.safe_path(filepath, "#{params[:file]}.#{params[:format]}")
    return head :no_content if filename.blank?
    return head :no_content unless filename.start_with?(File.realpath(filepath) + File::SEPARATOR)

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
      return false unless entity.valid?
      return false if entity.tombstone?

      return true if entity.published? || entity.parent.published?
      return true if valid_share_link?(entity.parent&.noid)
      return true if current_ability.can?(:read, params[:id])
      return true if FeaturedRepresentative.where(file_set_id: params[:id]).any?

      false
    end

    def valid_share_link?(parent_id)
      share_link = params[:share] || session[:share_link]
      session[:share_link] = share_link if share_link.present?

      return false if share_link.blank? || parent_id.blank?

      begin
        decoded = JsonWebToken.decode(share_link)
        decoded[:data] == parent_id
      rescue JWT::ExpiredSignature, JWT::VerificationError
        false
      end
    end
end
