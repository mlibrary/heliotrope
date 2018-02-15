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
    else
      Rails.logger.debug "[AUTHN] sessions#new, fake user session (1 of 2)"
      # sign in unsuccessful - fake HTTP Authentication
      @session = Session.new
      render '/sessions/new'
    end
  end

  def create
    # Submit action of sessions new form - fake HTTP Authentication
    Rails.logger.debug "[AUTHN] sessions#create, fake user session (2 of 2)"
    email = session_params[:email]
    user = email.split('@').first
    ENV['FAKE_HTTP_X_REMOTE_USER'] = user
    redirect_to new_user_session_path
  end

  def destroy
    # User sign out action - Step 1 of 2
    Rails.logger.debug "[AUTHN] sessions#destroy, user sign out (1 of 2)"
    user_sign_out_prompt
  end

  def terminate
    # User sign out action - Step 2 of 2
    Rails.logger.debug "[AUTHN] sessions#terminate, user sign out (2 of 2)"
    # Called only if user has confirmed sign out request
    redirect_to_url = stored_location_for(:user)
    user_sign_out
    ENV['FAKE_HTTP_X_REMOTE_USER'] = '(null)'
    sign_out_static_cookie
    redirect_to redirect_to_url || root_url
  end

  private

    def session_params
      params.require(:session).permit(:email)
    end
end
