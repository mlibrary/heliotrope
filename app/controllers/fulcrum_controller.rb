# frozen_string_literal: true

class FulcrumController < ApplicationController
  before_action :authenticate_user!

  def dashboard
    redirect_to action: :index, partials: :dashboard
  end

  def index
    @partials = params[:partials]
    if ['dashboard', 'products', 'components', 'individuals', 'institutions', 'publishers', 'users', 'tokens', 'logs', 'grants', 'monographs', 'assets', 'pages', 'reports', 'customize', 'settings', 'help', 'csv'].include? @partials
      incognito(incognito_params(params)) if /incognito/i.match?(params['submit'] || '')
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

  private

    def incognito_params(params)
      params.slice(:platform_admin, :hyrax_can, :action_permitted)
    end

    def incognito(options)
      Incognito.allow_all(current_actor)
      options.each do |key, _value|
        case key
        when 'platform_admin'
          Incognito.allow_platform_admin(current_actor, false)
        when 'hyrax_can'
          Incognito.allow_hyrax_can(current_actor, false)
        when 'action_permitted'
          Incognito.allow_action_permitted(current_actor, false)
        end
      end
    end
end
