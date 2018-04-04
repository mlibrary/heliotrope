# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :authenticate_user!

  def index
    @users = UsersPresenter.new(current_user)
    authorize! :read, @users
  end

  def show
    @user = UserPresenter.new(User.find(params[:id]), current_user)
    authorize! :read, @user
  end

  def tokenize
    @user = User.find(params[:id])
    authorize! :update, @user
    @user.tokenize!
    redirect_to main_app.partial_fulcrum_path(partial: :tokens)
  end
end
