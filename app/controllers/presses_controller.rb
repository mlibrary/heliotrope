class PressesController < ApplicationController
  load_and_authorize_resource find_by: :subdomain
  def index
  end

  def show
  end
end
