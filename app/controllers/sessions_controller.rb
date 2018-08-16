# frozen_string_literal: true

# Replaces Devise SessionsController
class SessionsController < ApplicationController
  def new
    # Called after HTTP_X_REMOTE_USER authentication
    if user_signed_in?
      Rails.logger.debug "[AUTHN] sessions#new, user signed in"
      # sign in successful - redirect back to where user came from (see Devise::Controllers::StoreLocation#stored_location_for)
      sign_in_static_cookie
      redirect_to return_location
    elsif Rails.env.production?
      production_fallback!
    else
      redirect_to new_authentications_path
    end
  end

  # Initiate a Shibboleth login through the Service Provider using the Default Identity Provider
  def default_login
    session[:log_me_in] = true
    session.delete(:dlpsInstitutionId)
    params[:entityID] = Settings.shibboleth.default_idp.entity_id
    params[:resource] = return_location
    redirect_to sp_login_url
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
    saved_return_location = return_location
    user_sign_out
    session.delete(:log_me_in)
    ENV['FAKE_HTTP_X_REMOTE_USER'] = '(null)'
    sign_out_static_cookie
    redirect_to saved_return_location
  end

  def discovery_feed
    id = params[:id] || ''
    institutions = []
    component = Component.find_by(handle: '2027/fulcrum.' + id)
    if component.present?
      lessees = component.lessees(true)
      if lessees.present?
        institutions = Institution.where(identifier: lessees.pluck(:identifier))
      end
    end
    institutions = Set.new(institutions.map(&:entity_id))
    feed = Rails.cache.fetch("disco:" + id, expires_in: 15.minutes) do
      obj_disco_feed = unfiltered_discovery_feed
      obj_filtered_disco_feed = obj_disco_feed
      unless institutions.empty?
        obj_filtered_disco_feed = []
        obj_disco_feed.each do |entry|
          obj_filtered_disco_feed << entry if entry["entityID"].in?(institutions)
        end
      end
      obj_filtered_disco_feed
    end
    render json: feed
  end

  private

    def unfiltered_discovery_feed
      json = if /^production$/i.match?(Rails.env)
               Faraday.get("/Shibboleth.sso/DiscoFeed").body
             else
               File.read(Rails.root.join('config', 'discovery_feed.json'))
             end
      JSON.parse(json)
    end

    def return_location
      rl = stored_location_for(:user)
      rl ||= root_path
      rl
    end

    def shib_target
      target = params[:resource] || return_location
      target = CGI.unescape(target)
      return target if target.start_with?('/')
      target.prepend('/')
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
    # normal redirect to the resource or root. If it fails, we redirect to
    # the app's default IdP.
    #
    # Note that this calls user_signed_in? to do a passive authentication check.
    # Calling authenticate_user! would force a redirect loop to /login if the
    # Shibboleth session is not established.
    def production_fallback!
      session[:log_me_in] = true
      if user_signed_in?
        redirect_to return_location
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
