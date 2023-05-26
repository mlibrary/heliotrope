# frozen_string_literal: true

class EBookDownloadPresenter < ApplicationPresenter
  include ActionView::Helpers::UrlHelper
  attr_reader :monograph, :current_ability, :current_actor, :ebook_presenters

  def initialize(monograph_presenter, current_ability, current_actor)
    @monograph = monograph_presenter
    @current_ability = current_ability
    @current_actor = current_actor
    # note the order here is the order that will end up in the ebook download dropdown options
    @ebook_presenters = Hyrax::PresenterFactory.build_for(ids: [@monograph.epub_id, @monograph.mobi_id, @monograph.pdf_ebook_id, @monograph.audiobook_id], presenter_class: Hyrax::FileSetPresenter, presenter_args: @current_ability).compact
    @ebook_presenters.each do |ebook|
      ebook_format = if ebook.audiobook?
                       # one full-book mp3 file, or a zip which contains several mp3 files, e.g. one per chapter/section
                       "AUDIO BOOK MP3" # wording requested by Fulcrum Steering, even if the download is a zip file
                     elsif ebook.epub?
                       "EPUB"
                     elsif ebook.mobi?
                       "MOBI"
                     elsif ebook.pdf_ebook?
                       "PDF"
                     end
      ebook.class_eval { attr_accessor "ebook_format" }
      ebook.instance_variable_set(:@ebook_format, ebook_format)
    end
  end

  def audiobook
    @ebook_presenters.filter_map { |ebook| ebook if ebook.audiobook? }.first
  end

  def epub
    @ebook_presenters.filter_map { |ebook| ebook if ebook.epub? }.first
  end

  def mobi
    @ebook_presenters.filter_map { |ebook| ebook if ebook.mobi? }.first
  end

  def pdf_ebook
    @ebook_presenters.filter_map { |ebook| ebook if ebook.pdf_ebook? }.first
  end

  def downloadable?(ebook_presenter)
    Rails.logger.debug { "[EBOOK DOWNLOAD] ebook_presenter.blank? #{ebook_presenter.blank?} (#{ebook_presenter.class})" }
    return false if ebook_presenter.blank?
    EbookDownloadOperation.new(current_actor, Sighrax.from_presenter(ebook_presenter)).allowed?
  end

  def downloadable_ebooks?
    @ebook_presenters.each do |ebook|
      return true if downloadable?(ebook)
    end
    false
  end

  def csb_download_links
    links = []

    @ebook_presenters.each do |ebook|
      next unless downloadable?(ebook)

      links << {
        format: ebook.ebook_format,
        size: ActiveSupport::NumberHelper.number_to_human_size(ebook.file_size),
        href: Rails.application.routes.url_helpers.download_ebook_path(ebook.id)
      }
    end

    links
  end
end
