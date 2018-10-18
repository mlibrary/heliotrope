# frozen_string_literal: true

class FulcrumController < ApplicationController
  before_action :authenticate_user!
  def index
    redirect_to action: :show, partial: :home
  end

  def show
    @partial = params[:partial]
    if ['home', 'products', 'product_noids', 'policies', 'components', 'lessees', 'institutions', 'publishers', 'users', 'tokens', 'logs', 'monographs', 'assets', 'pages', 'reports', 'customize', 'settings', 'help', 'csv'].include? @partial
      render
    else
      render 'hyrax/base/unauthorized', status: :unauthorized
    end
  end
end
