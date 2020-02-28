# frozen_string_literal: true

class PDFEbookPresenter < ApplicationPresenter
  def initialize(pdf_ebook)
    @pdf_ebook = pdf_ebook
  end

  def id
    @pdf_ebook.id
  end

  def multi_rendition?
    false
  end

  def intervals?
    @pdf_ebook&.intervals&.count&.positive?
  end

  def intervals
    @pdf_ebook.intervals.map { |interval| EPubIntervalPresenter.new(interval) }
  end
end
