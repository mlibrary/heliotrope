# frozen_string_literal: true

class FulcrumController < ApplicationController
  before_action :authenticate_user!

  def index
    redirect_to action: :show, partial: :dashboard
  end

  def show
    @partial = params[:partial]
    if ['dashboard', 'products', 'components', 'individuals', 'institutions', 'publishers', 'users', 'tokens', 'logs', 'policies', 'monographs', 'assets', 'pages', 'reports', 'customize', 'settings', 'help', 'csv'].include? @partial
      render
    else
      render 'hyrax/base/unauthorized', status: :unauthorized
    end
  end
end
