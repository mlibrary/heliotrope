# frozen_string_literal: true

class EPubDownloadPresenter < ApplicationPresenter
  include ActionView::Helpers::UrlHelper
  attr_reader :epub, :monograph, :mobi, :pdf_ebook, :current_ability

  def initialize(epub_presenter, monograph_presenter, current_ability)
    @epub = epub_presenter
    @monograph = monograph_presenter
    @current_ability = current_ability
  end

  def mobi
    @mobi ||= Hyrax::PresenterFactory.build_for(ids: [@monograph.mobi_id], presenter_class: Hyrax::FileSetPresenter, presenter_args: @current_ability).first
  end

  def pdf_ebook
    @pdf_ebook ||= Hyrax::PresenterFactory.build_for(ids: [@monograph.pdf_ebook_id], presenter_class: Hyrax::FileSetPresenter, presenter_args: @current_ability).first
  end

  def download_links
    links = []

    if epub.allow_download?
      links << {
        format: 'EPUB',
        size: ActiveSupport::NumberHelper.number_to_human_size(epub.file_size),
        href: Hyrax::Engine.routes.url_helpers.download_path(epub.id)
      }
    end

    if mobi&.allow_download?
      links << {
        format: 'MOBI',
        size: ActiveSupport::NumberHelper.number_to_human_size(mobi.file_size),
        href: Hyrax::Engine.routes.url_helpers.download_path(mobi.id)
      }
    end

    if pdf_ebook&.allow_download?
      links << {
        format: 'PDF',
        size: ActiveSupport::NumberHelper.number_to_human_size(pdf_ebook.file_size),
        href: Hyrax::Engine.routes.url_helpers.download_path(pdf_ebook.id)
      }
    end

    links
  end
end
