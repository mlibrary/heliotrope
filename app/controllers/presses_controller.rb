# frozen_string_literal: true

class PressesController < ApplicationController
  load_and_authorize_resource find_by: :subdomain

  def index
    authorize!(:index, Press)
    @presses = Press.all
  end

  def new
    @press = Press.new
  end

  def create
    @press = Press.create(press_params)
    if @press.save
      redirect_to presses_path
    else
      render :new, layout: false
    end
  end

  def edit; end

  def update
    if @press.update(press_params)
      redirect_to presses_path
    else
      render :edit, layout: false
    end
  end

  private

    def press_params
      params.require(:press).permit(:subdomain, :name, :logo_path, :description, :press_url, :google_analytics, :typekit, :footer_block_a, :footer_block_b, :footer_block_c, :remove_logo_path, :parent_id, :restricted_message, :twitter, :location, :google_analytics_url)
    end
end
