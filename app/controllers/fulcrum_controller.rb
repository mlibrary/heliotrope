# frozen_string_literal: true

class FulcrumController < ApplicationController
  before_action :authenticate_user!

  def dashboard
    redirect_to action: :index, partials: :dashboard
  end

  def index
    @partials = params[:partials]
    if ['dashboard', 'products', 'components', 'individuals', 'institutions', 'publishers', 'users', 'tokens', 'logs', 'grants', 'monographs', 'assets', 'pages', 'reports', 'customize', 'settings', 'help', 'csv'].include? @partials
      render
    else
      render 'hyrax/base/unauthorized', status: :unauthorized
    end
  end

  def show
    @partials = params[:partials]
    if ['products', 'components', 'individuals', 'institutions', 'publishers', 'users'].include? @partials
      @identifier = Base64.urlsafe_decode64(params[:id])
      render
    else
      render 'hyrax/base/unauthorized', status: :unauthorized
    end
  end
end
