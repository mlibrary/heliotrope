# frozen_string_literal: true

module TitlePresenter
  extend ActiveSupport::Concern

  def page_title
    MarkdownService.markdown_as_text(md_title)
  end

  def title
    MarkdownService.markdown(md_title)
  end

  private

    def md_title
      md = solr_document&.title&.first
      md = 'Title' if md.blank?
      md
    end
end
