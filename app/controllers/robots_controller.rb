class RobotsController < ApplicationController
  caches_page :robots

  def robots
    env = Rails.env
    env = 'staging' if Socket.gethostname == 'nectar'

    robots = File.read(Rails.root + "config/robots/robots.#{env}.txt")
    render text: robots, layout: false, content_type: "text/plain"
  end
end
