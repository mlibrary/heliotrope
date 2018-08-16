# frozen_string_literal: true

class ShibbolethsController < CheckpointController
  def help; end

  # This listens on Shibboleth.sso/Login in development mode...
  # When we get here from /shib_login, what typically happens is:
  # 1.  session[:log_me_in] is already set
  # 2.  we redirect to target query param (/shib_session/:resource)
  # 3.  authenticate_user! will fail, storing the location and redirecting to /login
  # 4.  sessions#new will redirect to authentications#new, giving a dummy login form
  # 5.  authentications#create will set the FAKE_HTTP_X_REMOTE_USER env var and redirect to sessions#new
  # 6.  FakeAuthHeader middleware will set REMOTE_USER from the env var
  # 7.  sessions#new will call authenticate_user!
  # 8.  the Keycard strategy picks up the log_me_in flag and the REMOTE_USER, succeeding
  # 9.  sessions#new will redirect to the stored location (/shib_session/:resource)
  # 10. authenticate_user! will now pass, and we redirect to params[:resource]
  def new
    redirect_to params[:target] || new_user_session_path
  end
end
