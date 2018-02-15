# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Remember where a user is to redirect to on sign in and sign out
  # https://github.com/plataformatec/devise/wiki/How-To:-Redirect-back-to-current-page-after-sign-in,-sign-out,-sign-up,-update
  # The callback which stores the current location must be added before you authenticate the user
  # as `authenticate_user!` (or whatever your resource is) will halt the filter chain and redirect
  # before the location can be stored.
  before_action :store_user_location!, if: :storable_location?

  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  include Hydra::Controller::ControllerBehavior

  # Adds Hyrax behaviors to the application controller.
  include Hyrax::Controller
  include Hyrax::ThemedLayoutController
  with_themed_layout '1_column'

  # Behavior for devise.  Use remote user field in http header for auth.
  include Behaviors::HttpHeaderAuthenticatableBehavior

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  rescue_from ActiveFedora::ObjectNotFoundError, with: :render_unauthorized
  # rescue_from ActiveFedora::ActiveFedoraError, with: :render_unauthorized
  rescue_from ActiveRecord::RecordNotFound, with: :render_unauthorized

  # Clears any user session and authorization information
  before_action :clear_session_user

  # register callback with warden to clear flash message
  Warden::Manager.after_authentication do |user, auth, _opts|
    Rails.logger.debug "[AUTHN] Warden after_authentication (clearing flash): #{user}"
    auth.request.flash.clear
  end

  protected

    def render_unauthorized(_exception)
      respond_to do |format|
        format.html { render 'hyrax/base/unauthorized', status: :unauthorized }
        format.any { head :unauthorized, content_type: 'text/plain' }
      end
    end

  private

    # Clears any user session and authorization information by:
    #   * ensuring the user will be logged out if REMOTE_USER is not set
    def clear_session_user
      return nil_request if request.nil?
      search = session[:search].dup if session[:search]
      redirect_to_url = stored_location_for(:user)
      if valid_user_signed_in?
        sign_in_static_cookie
      else
        sign_out_static_cookie
        request.env['warden'].logout
      end
      session[:search] = search
      store_location_for(:user, redirect_to_url)
    end

    def valid_user_signed_in?
      user_signed_in? && (valid_user?(request.headers) || Rails.env.test?)
    end

    def user_sign_out_prompt
      Rails.logger.debug "[AUTHN] user_sign_out_prompt: #{current_user.try(:email) || '(no user)'}"
      redirect_to Hyrax::Engine.config.cosign_logout_url + terminate_user_session_url
    end

    def user_sign_out
      Rails.logger.debug "[AUTHN] user_sign_out: #{current_user.try(:email) || '(no user)'}"
      sign_out(:user)
      cookies.delete("cosign-" + Hyrax::Engine.config.hostname, path: '/')
      sign_out_static_cookie
      session.destroy
      flash.clear
    end

    # Its important that the location is NOT stored if:
    # - The request method is not GET (non idempotent)
    # - The request is handled by a Devise controller such as Devise::SessionsController as that could cause an
    #    infinite redirect loop.
    # - The request is an Ajax request as this can lead to very unexpected behaviour.
    def storable_location? # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      return false unless request.get?
      return false unless is_navigational_format?
      return false if devise_controller?
      return false if is_a?(::SessionsController)
      return false if request.xhr?
      return false if request.url.match?(/image-service/)
      return false if request.url.match?(/downloads/)
      return false if request.url.match?(/dashboard/)
      true
    end

    def store_user_location!
      # :user is the scope we are authenticating
      # store_location_for(:user, request.fullpath)
      store_location_for(:user, request.url)
    end

    # This cookie is strictly here for the fulcrum static/jekyll pages,
    # specifically to show either "Log In" or "Log Out" in the footer.
    # Nothing more. So it is unencrypted and unsigned. Don't do anything
    # important with this as it's not secure. see #863
    def sign_in_static_cookie
      cookies[:fulcrum_signed_in_static] = true
    end

    def sign_out_static_cookie
      cookies.delete :fulcrum_signed_in_static
    end
end
