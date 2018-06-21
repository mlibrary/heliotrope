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
      render
    else
      redirect_to new_authentications_path
    end
  end

  def create
    head :bad_request
  end

  def destroy
    Rails.logger.debug "[AUTHN] sessions#destroy, user sign out"
    redirect_to_url = stored_location_for(:user)
    user_sign_out
    ENV['FAKE_HTTP_X_REMOTE_USER'] = '(null)'
    sign_out_static_cookie
    redirect_to redirect_to_url || root_url
  end
end
