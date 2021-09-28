# frozen_string_literal: true

class AuthenticationsController < ApplicationController
  before_action :set_presenter, only: %i[show]

  def show
    redirect_to default_login_path unless @presenter.publisher?
  end

  def new
    @authentication = Authentication.new
  end

  def create
    ENV['FAKE_HTTP_X_REMOTE_USER'] = authentication_params[:email]
    session[:log_me_in] = true
    redirect_to new_user_session_path
  end

  def destroy
    ENV['FAKE_HTTP_X_REMOTE_USER'] = nil
    session.delete(:log_me_in)
    redirect_to stored_location_for(:user) || root_url
  end

  private

    def set_presenter
      @presenter = AuthenticationPresenter.for(current_actor, params[:press], params[:id], params[:filter])
    end

    def authentication_params
      params.require(:authentication).permit(:email)
    end
end
