# frozen_string_literal: true

class PDFEbookPresenter < ApplicationPresenter
  attr_reader :id
  # commented out during Hyrax 4 upgrade (see HELIO-4582)
  # TODO: put Skylight back in action post-upgrade (see HELIO-4589)
  # include Skylight::Helpers

  # commented out during Hyrax 4 upgrade (see HELIO-4582)
  # TODO: put Skylight back in action post-upgrade (see HELIO-4589)
  # instrument_method
  def initialize(id)
    @id = id
    @cached = EbookTableOfContentsCache.find_by(noid: @id)
    load_pdf if @cached.blank?
  end

  # commented out during Hyrax 4 upgrade (see HELIO-4582)
  # TODO: put Skylight back in action post-upgrade (see HELIO-4589)
  # instrument_method
  def load_pdf
    # HELIO-4467
    # Parsing the entire pdf can be very expensive so don't do it unless we need it
    # We shouldn't ever need it in this presenter, but there are times when a pdf doesn't have a cached ToC
    # It's really considered an error, but not really worth giving users a 500
    Rails.logger.error("[FIXME ERROR PDFEbookPresenter: EbookTableOfContentsCache] No Cached TOC for #{@id}")
    @pdf_ebook ||= PDFEbook::Publication.from_path_id(UnpackService.root_path_from_noid(@id, 'pdf_ebook') + ".pdf", @id)
  end

  def multi_rendition?
    false
  end

  # commented out during Hyrax 4 upgrade (see HELIO-4582)
  # TODO: put Skylight back in action post-upgrade (see HELIO-4589)
  # instrument_method
  def intervals?
    return true if @cached.present?
    @pdf_ebook&.intervals&.count&.positive?
  end

  # commented out during Hyrax 4 upgrade (see HELIO-4582)
  # TODO: put Skylight back in action post-upgrade (see HELIO-4589)
  # instrument_method
  def intervals
    @intervals ||= begin
      record = @cached
      if record.present?
        JSON.parse(record.toc).map { |i| EBookIntervalPresenter.new(i.symbolize_keys) }
      else
        @pdf_ebook.intervals.map { |interval| RemoveMeEPubIntervalPresenter.new(interval) }
      end
    end
  end
end
