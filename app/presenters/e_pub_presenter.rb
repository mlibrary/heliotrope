# frozen_string_literal: true

class EPubPresenter < ApplicationPresenter
  def initialize(epub)
    @epub = epub
  end

  def multi_rendition?
    @epub.multi_rendition?
  end

  def intervals
    @epub.rendition.intervals.map { |interval| EPubIntervalPresenter.new(interval) }
  end
end
