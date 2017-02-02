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
end
