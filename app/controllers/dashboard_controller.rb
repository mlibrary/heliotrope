# frozen_string_literal: true

class DashboardController < ApplicationController
  before_action :authenticate_user!
  def index
    redirect_to action: :show, partial: :home
  end

  def show
    @partial = params[:partial]
    if ['home', 'publishers', 'users', 'monographs', 'assets', 'pages', 'reports', 'customize', 'settings', 'help'].include? @partial
      render
    else
      render 'hyrax/base/unauthorized', status: :unauthorized
    end
  end
end
