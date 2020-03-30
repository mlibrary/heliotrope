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
    @intervals ||= begin
      record = PDFIntervalRecord.find_by(noid: @pdf_ebook.id)
      if record.nil?
        intervals = @pdf_ebook.intervals
        PDFIntervalRecord.create(noid: @pdf_ebook.id, data: intervals.map { |i| i.to_h }.to_json)
        intervals.map { |i| EPubIntervalPresenter.new(i) }
      else
        JSON.parse(record.data).map { |i| EPubIntervalPresenter.new(PDFEbook::Interval.from_h(i)) }
      end
    end
  end
end
