# frozen_string_literal: true

class AnalyticsController < ApplicationController
  before_action :authenticate_user!

  def show
    if current_user.platform_admin?
      @analytics = AnalyticsPresenter.new(current_user)
      render
    else
      render 'hyrax/base/unauthorized', status: :unauthorized
    end
  end
end
