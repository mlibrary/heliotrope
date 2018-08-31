# frozen_string_literal: true

class EPubIntervalPresenter < ApplicationPresenter
  delegate :title, :level, :cfi, :downloadable?, to: :@interval

  def initialize(interval)
    @interval = interval
  end
end
