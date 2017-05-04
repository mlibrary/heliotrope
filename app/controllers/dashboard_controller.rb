# frozen_string_literal: true

class DashboardController < ApplicationController
  before_action :authenticate_user!
  def index
    redirect_to action: :show, partial: :home
  end

  def show
    @partial = params[:partial]
    if ['home', 'publishers', 'users', 'books', 'items', 'pages', 'reports', 'customize', 'settings', 'help'].include? @partial
      render
    else
      render 'curation_concerns/base/unauthorized', status: :unauthorized
    end
  end
end
