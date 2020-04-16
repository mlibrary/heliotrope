# frozen_string_literal: true

class EPubPresenter < ApplicationPresenter
  def initialize(epub)
    @epub = epub
  end

  def id
    @epub.id
  end

  def multi_rendition?
    @epub.multi_rendition?
  end

  def intervals?
    return true if EbookTableOfContentsCache.find_by(noid: id).present?
    @epub&.rendition&.intervals&.count&.positive?
  end

  def intervals
    @intervals ||= begin
      record = EbookTableOfContentsCache.find_by(noid: @epub.id)
      if record.present?
        JSON.parse(record.toc).map do |i|
          EBookIntervalPresenter.new(i.symbolize_keys)
        end
      else
        Rails.logger.error("[FIXME ERROR EPubPresenter: EbookTableOfContentsCache] No Cached TOC for #{@epub.id}")
        @epub.rendition.intervals.map { |interval| RemoveMeEPubIntervalPresenter.new(interval) }
      end
    end
  end
end
