# frozen_string_literal: true

class FulcrumController < ApplicationController
  before_action :authenticate_user!

  def dashboard
    redirect_to action: :index, partials: :dashboard
  end

  def index
    @partials = params[:partials]
    @individuals = []
    @institutions = []
    if ['dashboard', 'products', 'components', 'individuals', 'institutions', 'publishers', 'users', 'tokens', 'logs', 'grants', 'monographs', 'assets', 'pages', 'reports', 'customize', 'settings', 'help', 'csv'].include? @partials
      if /dashboard/.match?(@partials)
        @individuals = Individual.where("identifier like ? or name like ?", "%#{params['individual_filter']}%", "%#{params['individual_filter']}%").map { |individual| ["#{individual.identifier} (#{individual.name})", individual.id] }
        @institutions = Institution.where("identifier like ? or name like ?", "%#{params['institution_filter']}%", "%#{params['institution_filter']}%").map { |institution| ["#{institution.identifier} (#{institution.name})", institution.id] }
      end
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
      params.slice(:actor, :platform_admin, :hyrax_can, :action_permitted)
    end

    def incognito(options) # rubocop:disable Metrics/CyclomaticComplexity
      Incognito.reset(current_actor)
      options.each do |key, _value|
        case key
        when 'actor'
          Incognito.sudo_actor(current_actor, true, params[:individual_id] || 0, params[:institution_id] || 0)
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
