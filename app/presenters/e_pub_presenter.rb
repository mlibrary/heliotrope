# frozen_string_literal: true

class EPubPresenter < ApplicationPresenter
  def initialize(epub)
    @epub = epub
  end

  def multi_rendition?
    @epub.multi_rendition?
  end

  def sections
    @epub.sections.map { |section| EPubSectionPresenter.new(section) }
  end
end
