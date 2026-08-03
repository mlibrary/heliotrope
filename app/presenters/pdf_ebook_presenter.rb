# frozen_string_literal: true

class PDFEbookPresenter < ApplicationPresenter
  attr_reader :id

  def initialize(id)
    @id = id
  end

  def intervals?
    EbookTableOfContentsCache.find_by(noid: id).present?
  end

  def intervals
    return @intervals if defined?(@intervals)
    record = EbookTableOfContentsCache.find_by(noid: @id)
    @intervals = if record.present?
                   JSON.parse(record.toc).map { |i| EBookIntervalPresenter.new(i.symbolize_keys) }
                 else
                   # No cached ToC. The previous fallback that parsed the entire
                   # PDF on-the-fly (via PDFEbook::Publication) has been removed in
                   # favor of a single source of truth (the ToC cache built by
                   # UnpackJob#cache_pdf_toc). A missing cache is an error that
                   # should be caught during QC before the book is published, so
                   # we just log and return nil here.
                   Rails.logger.error("[FIXME ERROR PDFEbookPresenter: EbookTableOfContentsCache] No Cached TOC for #{@id}")
                   nil
                 end
  end
end
