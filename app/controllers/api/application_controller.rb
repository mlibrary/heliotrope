# frozen_string_literal: true

module API
  class ApplicationController < ActionController::API
    respond_to :json
    before_action :authorize_request

    attr_reader :current_user

    rescue_from ActiveRecord::RecordNotFound, StandardError do |exception|
      case exception
      when ActiveRecord::RecordInvalid
        render json: { exception: exception.inspect }, status: :unprocessable_entity
      when ActiveRecord::RecordNotFound
        render json: { exception: exception.inspect }, status: :not_found
      else
        render json: { exception: exception.inspect }, status: :unauthorized
      end
    end

    private

      def authorize_request
        @current_user = platform_admin_from_payload(payload_from_token(token_from_header))
      end

      def platform_admin_from_payload(payload)
        user = User.find_by(email: payload[:email])
        raise("User #{payload[:email]} not found.") if user.blank?
        raise("User #{payload[:email]} pin no longer valid.") if payload[:pin] != user.encrypted_password
        raise("User #{payload[:email]} not a platform administrator.") unless user.platform_admin?
        user
      end

      def payload_from_token(token)
        payload = JsonWebToken.decode(token)
        raise("Token payload blank.") if payload.blank?
        raise("Token payload email blank.") if payload[:email].blank?
        raise("Token payload pin blank.") if payload[:pin].blank?
        payload
      end

      def token_from_header
        raise("HTTP Authorization request header blank.") if request.headers['Authorization'].blank?
        token = request.headers['Authorization'].split(' ').last
        raise("HTTP Authorization request header hash corrupt.") if token.blank?
        token
      end
  end
end
