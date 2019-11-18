# frozen_string_literal: true

class PressStatisticsPresenter < ApplicationPresenter
  def initialize(press)
    @press = press
  end

  def subdomain
    @press.subdomain
  end
end
