# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Remember where a user is to redirect to on sign in and sign out
  # https://github.com/plataformatec/devise/wiki/How-To:-Redirect-back-to-current-page-after-sign-in,-sign-out,-sign-up,-update
  # The callback which stores the current location must be added before you authenticate the user
  # as `authenticate_user!` (or whatever your resource is) will halt the filter chain and redirect
  # before the location can be stored.
  before_action :store_user_location!, if: :storable_location?

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  include Hydra::Controller::ControllerBehavior
  # hyrax 2.1 upgrade
  skip_after_action :discard_flash_if_xhr

  # Adds Hyrax behaviors to the application controller.
  include Hyrax::Controller
  include Hyrax::ThemedLayoutController
  with_themed_layout '1_column'

  rescue_from ActiveFedora::ObjectNotFoundError, with: :render_unauthorized
  # rescue_from ActiveFedora::ActiveFedoraError, with: :render_unauthorized
  rescue_from ActiveRecord::RecordNotFound, with: :render_unauthorized

  # TODO: See gkostin about this comment if you have any questions.
  # Ensure CanCan by authorize!(<action>, <resource> || <resouce_class>)
  # rescue_from CanCan::AccessDenied, with: :render_unauthorized # TODO: Might be needed
  # check_authorization unless: :devise_controller? || :checkpoint_controller?

  def current_actor
    current_user || Anonymous.new(request_attributes)
  end

  def current_institutions?
    current_institutions.count.positive?
  end

  def current_institutions
    if session[:dlpsInstitutionId]
      insts = Institution.where(identifier: session[:dlpsInstitutionId]).to_a
    else
      insts = (ip_based_institutions + shib_institutions).uniq
      session[:dlpsInstitutionId] = insts.map(&:identifier).map(&:to_s)
    end
    insts
  end

  private

    def request_attributes
      @request_attributes ||= Services.request_attributes.for(request)
    end

    def ip_based_institutions
      ids = request_attributes[:dlpsInstitutionId] || []
      Institution.where(identifier: ids).to_a
    end

    def shib_institutions
      entity_id = request_attributes[:identity_provider]
      if entity_id
        Institution.where(entity_id: entity_id).to_a
      else
        []
      end
    end

    def checkpoint_controller?
      false # Overridden in CheckpointController to return true
    end

    # register callback with warden to clear flash message
    Warden::Manager.after_authentication do |user, auth, _opts|
      Rails.logger.debug "[AUTHN] Warden after_authentication (clearing flash): '#{user}'"
      auth.request.flash.clear
    end

    def render_unauthorized(_exception)
      respond_to do |format|
        format.html { render 'hyrax/base/unauthorized', status: :unauthorized }
        format.any { head :unauthorized, content_type: 'text/plain' }
      end
    end

    def valid_user_signed_in?
      user_signed_in? && current_user.email.present?
    end

    def user_sign_out
      sign_out(:user)
      session.destroy
      flash.clear
    end

    # Its important that the location is NOT stored if:
    # - The request method is not GET (non idempotent)
    # - The request is handled by a Devise controller such as Devise::SessionsController as that could cause an
    #    infinite redirect loop.
    # - The request is an Ajax request as this can lead to very unexpected behaviour.
    def storable_location? # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      return false unless is_a?(PressCatalogController) || is_a?(::MonographCatalogController) || is_a?(::Hyrax::FileSetsController)
      return false unless request.get? || is_navigational_format?
      return false if request.xhr?
      return false if request.url.match?(/image-service/)
      return false if request.url.match?(/downloads/)
      return false if request.url.match?(/dashboard/)
      true
    end

    def store_user_location!
      # :user is the scope we are authenticating
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
