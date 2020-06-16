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
    return true if EbookTableOfContentsCache.find_by(noid: @pdf_ebook.id).present?
    @pdf_ebook&.intervals&.count&.positive?
  end

  def intervals
    @intervals ||= begin
      record = EbookTableOfContentsCache.find_by(noid: @pdf_ebook.id)
      if record.present?
        JSON.parse(record.toc).map { |i| EBookIntervalPresenter.new(i.symbolize_keys) }
      else
        Rails.logger.error("[FIXME ERROR PDFEbookPresenter: EbookTableOfContentsCache] No Cached TOC for #{@pdf_ebook.id}")
        @pdf_ebook.intervals.map { |interval| RemoveMeEPubIntervalPresenter.new(interval) }
      end
    end
  end
end
