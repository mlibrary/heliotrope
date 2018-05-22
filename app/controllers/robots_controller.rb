# frozen_string_literal: true

class RobotsController < ApplicationController
  caches_page :robots

  def robots
    env = Rails.env
    env = 'not_production' if Socket.gethostname == 'nectar.umdl.umich.edu'

    robots = File.read(Rails.root + "config/robots/robots.#{env}.txt")
    render plain: robots, layout: false, content_type: "text/plain"
  end
end
