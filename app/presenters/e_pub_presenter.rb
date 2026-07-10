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
    EbookTableOfContentsCache.find_by(noid: id).present?
  end

  def intervals
    return @intervals if defined?(@intervals)
    record = EbookTableOfContentsCache.find_by(noid: @epub.id)
    @intervals = if record.present?
                   JSON.parse(record.toc).map do |i|
                     EBookIntervalPresenter.new(i.symbolize_keys)
                   end
                 else
                   # No cached ToC. The previous fallback that rebuilt intervals
                   # from EPub::Rendition on-the-fly has been removed in favor
                   # of a single source of truth (EpubChaptersService, via
                   # UnpackJob#cache_epub_toc). If something went wrong with
                   # UnpackJob that should be noticed during QC before the
                   # book is published, so we just log and return nil here.
                   Rails.logger.error("[FIXME ERROR EPubPresenter: EbookTableOfContentsCache] No Cached TOC for #{@epub.id}")
                   nil
                 end
  end
end
