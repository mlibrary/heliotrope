# frozen_string_literal: true

# Replaces Devise SessionsController
class SessionsController < ApplicationController
  def new
    # Called after HTTP_X_REMOTE_USER authentication
    if user_signed_in?
      Rails.logger.debug "[AUTHN] sessions#new, user signed in"
      # sign in successful - redirect back to where user came from (see Devise::Controllers::StoreLocation#stored_location_for)
      sign_in_static_cookie
      redirect_to stored_location_for(:user) || hyrax.dashboard_path
    elsif Rails.env.production?
      production_fallback!
    else
      redirect_to new_authentications_path
    end
  end

  # Initiate a Shibboleth login through the Service Provider using the Default Identity Provider
  def default_login
    session.delete(:dlpsInstitutionId)
    redirect_to sp_login_url(Settings.shibboleth.default_idp.entity_id, stored_location_for(:user) || hyrax.dashboard_path)
  end

  # Initiate a Shibboleth login through the Service Provider
  def shib_login
    session[:log_me_in] = true
    session.delete(:dlpsInstitutionId)
    redirect_to sp_login_url
  end

  # Begin an application session based once Shibboleth login has happened
  def shib_session
    authenticate_user!
    redirect_to shib_target
  end

  def create
    head :bad_request
  end

  def destroy
    Rails.logger.debug "[AUTHN] sessions#destroy, user sign out"
    redirect_to_url = stored_location_for(:user)
    user_sign_out
    session.delete(:log_me_in)
    ENV['FAKE_HTTP_X_REMOTE_USER'] = '(null)'
    sign_out_static_cookie
    redirect_to redirect_to_url || root_url
  end

  private

    def shib_target
      target = params[:resource] || root_path
      target = CGI.unescape(target)
      target = target.gsub(/(^\/*)(.*)/, '/\2')
      target
    end

    def sp_login_url(entity_id = params[:entityID], target = params[:resource])
      URI("#{Settings.shibboleth.sp.url}/Login").tap do |url|
        url.query = URI.encode_www_form(
          target: shib_session_url(target),
          entityID: entity_id
        )
      end.to_s
    end

    # This is a safety net for the case where #new (/login) is hit in
    # production directly. Generally, this path will have been intercepted by
    # the SP and redirected to its discovery or default IdP and only passed
    # through if authentication was successful.
    #
    # To deal with this scenario, we set the log_me_in flag and try to
    # authenticate again with Devise. If it succeeds, we proceed with the
    # normal redirect to the resource or dashboard. If it fails, we redirect to
    # the app's default IdP.
    #
    # Note that this calls user_signed_in? to do a passive authentication check.
    # Calling authenticate_user! would force a redirect loop to /login if the
    # Shibboleth session is not established.
    def production_fallback!
      session[:log_me_in] = true
      if user_signed_in?
        redirect_to stored_location_for(:user) || hyrax.dashboard_path
      elsif Settings.shibboleth.fallback_to_idp
        redirect_to shib_login_url(Settings.shibboleth.default_idp.entity_id)
      else
        # Bail out and show a failure page. This should be changed to a proper
        # 403 error page (or really, a 500 because this reflects a
        # configuration problem).
        render
      end
    end
end
