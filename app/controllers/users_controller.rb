# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :authenticate_user!

  def tokenize
    @user = User.find(params[:id])
    authorize! :update, @user
    @user.tokenize!
    redirect_to main_app.partial_fulcrum_path(partial: :tokens)
  end

  private

    # A list of the param names that can be used for filtering the Product list
    def filtering_params(params)
      params.slice(:email_like)
    end
end
