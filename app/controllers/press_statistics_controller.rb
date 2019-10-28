# frozen_string_literal: true

class PressStatisticsController < ApplicationController
  before_action :load_press

  def index
    render :index
  end

  private

    def load_press
      @press = Press.find_by(subdomain: params['press'])
      return @press if @press.present?
      render file: Rails.root.join('public', '404.html'), status: :not_found, layout: false
    end
end
