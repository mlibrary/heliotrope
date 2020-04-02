# frozen_string_literal: true

# Replaces Devise SessionsController
class SessionsController < ApplicationController
  skip_before_action :store_user_location!

  # Called after HTTP_X_REMOTE_USER authentication
  def new
    debug_log("new, user '#{current_user.try(:email) || '(null)'}'")
    if user_signed_in?
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
    debug_log("default_login, entityID(#{params[:entityID]}) resource(#{params[:resource]})")
    redirect_to sp_login_url
  end

  # Initiate a Shibboleth login through the Service Provider
  def shib_login
    session[:log_me_in] = true
    session.delete(:dlpsInstitutionId)
    debug_log("shib_login, entityID(#{params[:entityID]}) resource(#{params[:resource]})")
    redirect_to sp_login_url
  end

  # Begin an application session based once Shibboleth login has happened
  def shib_session
    debug_log("shib_session, shib_target(#{shib_target})")
    authenticate_user!
    redirect_to shib_target
  end

  def create
    debug_log("create")
    head :bad_request
  end

  def destroy
    debug_log("destroy, user '#{current_user.try(:email) || '(null)'}'")
    saved_return_location = return_location
    user_sign_out
    session.delete(:log_me_in)
    ENV['FAKE_HTTP_X_REMOTE_USER'] = '(null)'
    sign_out_static_cookie
    redirect_to saved_return_location
  end

  def discovery_feed
    render json: if params[:id].present?
                   child = Sighrax.from_noid(params[:id])
                   noid = child.noid
                   unless child.is_a?(Sighrax::Monograph)
                     noid = child.parent.noid
                   end
                   component_discovery_feed(noid)
                 else
                   unfiltered_discovery_feed
                 end
  end

  private

    def component_discovery_feed(component_id = '') # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      cache_key = 'component_discovery_feed:' + component_id
      return Rails.cache.read(cache_key) if Rails.cache.exist?(cache_key)

      component_discovery_feed = []
      component = Greensub::Component.find_by(noid: component_id)
      if component.present?
        products = component.products
        if products.present?
          institutions = []
          products.each { |product| institutions += product.institutions }
          if institutions.present?
            entity_ids = []
            institutions.each { |institution| entity_ids << institution.entity_id if institution.entity_id.present? } # rubocop:disable Metrics/BlockNesting
            if entity_ids.present? # rubocop:disable Metrics/BlockNesting
              filtered_discovery_feed.each do |entry|
                component_discovery_feed << entry if entry["entityID"].in?(entity_ids) # rubocop:disable Metrics/BlockNesting
              end
            end
          end
        end
      end

      return component_discovery_feed unless Rails.env.production?

      Rails.cache.fetch(cache_key, expires_in: 1.hour) do
        component_discovery_feed
      end
    end

    def filtered_discovery_feed
      cache_key = 'filtered_discovery_feed'
      return Rails.cache.read(cache_key) if Rails.cache.exist?(cache_key)

      filtered_discovery_feed = []
      institutions = Set.new(Greensub::Institution.where("entity_id <> ''").map(&:entity_id))
      if institutions.present?
        unfiltered_discovery_feed.each do |entry|
          filtered_discovery_feed << entry if entry["entityID"].in?(institutions)
        end
      end

      return filtered_discovery_feed unless Rails.env.production?

      Rails.cache.fetch(cache_key, expires_in: 12.hours) do
        filtered_discovery_feed
      end
    end

    def unfiltered_discovery_feed
      cache_key = RecacheInCommonMetadataJob::RAILS_CACHE_KEY
      return Rails.cache.read(cache_key) if Rails.cache.exist?(cache_key)

      RecacheInCommonMetadataJob.perform_now if Rails.env.production?

      job = RecacheInCommonMetadataJob.new
      job.download_xml unless File.exist?(RecacheInCommonMetadataJob::XML_FILE)
      job.parse_xml unless File.exist?(RecacheInCommonMetadataJob::JSON_FILE)
      job.load_json
    end

    def return_location
      rl = stored_location_for(:user)
      rl ||= root_path
      rl
    end

    def shib_target
      target = params[:resource] || return_location || ""
      target = CGI.unescape(target)
      match = /^(https?\:\/\/[^\/]+\/)(.*)$/i.match(target)
      target = match[2] if match.present?
      target = target.prepend('/') unless target.start_with?('/')
      target
    end

    def sp_login_url(entity_id = params[:entityID], target = params[:resource])
      URI("#{Settings.shibboleth.sp.url}/Login").tap do |url|
        url.query = URI.encode_www_form(
          target: shib_session_url(target),
          entityID: entity_id || Settings.shibboleth.default_idp.entity_id
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
        debug_log("production_fallback! redirect_to return_location")
        redirect_to return_location
      elsif Settings.shibboleth.fallback_to_idp
        debug_log("production_fallback! redirect_to sp_login_url")
        redirect_to sp_login_url
      else
        debug_log("production_fallback! render 500 because this reflects a configuration problem")
        render file: Rails.root.join('public', '500.html'), status: :internal_server_error, layout: false
      end
    end

    def debug_log(msg)
      Rails.logger.debug "[AUTHN] SessionsController -- #{msg}"
    end
end
