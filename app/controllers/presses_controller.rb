# frozen_string_literal: true

class PressesController < ApplicationController
  load_and_authorize_resource find_by: :subdomain
  def index; end
end
