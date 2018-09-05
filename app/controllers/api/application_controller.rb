# frozen_string_literal: true

module API
  # Base controller for API REST controllers
  # @note Responses only to JSON request
  # @note Uses JSON Web Token (JWT) to authenticate and authorize request
  # @note Rescues from ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound, and StandardError
  class ApplicationController < ActionController::API
    respond_to :json

    before_action :authorize_request
    after_action :log_request_response

    # User identification extracted from JWT
    # @return [User] the authenticated and authorized {User} of the current request
    attr_reader :current_user

    rescue_from ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound, StandardError do |exception|
      log_request_response(exception)
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
        @current_user = platform_admin_from_payload(payload_from_token(token_from_header_or_query))
      end

      def log_request_response(exception = nil)
        api_request = APIRequest.new
        api_request.user = @token_user
        api_request.action = request.method
        api_request.path = request.original_fullpath
        api_request.params = params.to_json
        api_request.status = response.status
        api_request.exception = exception
        begin
          api_request.save!
        rescue StandardError => e
          Rails.logger.error("EXCEPTION #{e} API_REQUEST #{api_request.user&.id}, #{api_request.action}, #{api_request.path}, #{api_request.params}, #{api_request.status}, #{api_request.exception}")
        end
      end

      def platform_admin_from_payload(payload)
        @token_user = User.find_by(email: payload[:email])
        raise("User #{payload[:email]} not found.") if @token_user.blank?
        raise("User #{payload[:email]} pin no longer valid.") if payload[:pin] != @token_user.encrypted_password
        raise("User #{payload[:email]} not a platform administrator.") unless @token_user.platform_admin?
        @token_user
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

      def token_from_query
        raise("ApiKey query blank.") if request.params['apikey'].blank?
        token = request.params['apikey'].split(' ').last
        raise("ApiKey query hash corrupt.") if token.blank?
        token
      end

      def token_from_header_or_query
        token = begin
                  token_from_header
                rescue StandardError => _e
                  nil
                end
        token ||= begin
                    token_from_query
                  rescue StandardError => _e
                    nil
                  end
        raise "HTTP Authorization or ApiKey query blank or corrupt." if token.blank?
        token
      end
  end
end
