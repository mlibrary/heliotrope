# frozen_string_literal: true

class EPubPresenter < ApplicationPresenter
  def initialize(epub)
    @epub = epub
  end

  def sections
    @epub.sections.map { |section| EPubSectionPresenter.new(section) }
  end
end
