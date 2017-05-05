# frozen_string_literal: true

module TitlePresenter
  extend ActiveSupport::Concern

  def page_title
    MarkdownService.markdown_as_text(solr_document.title.first)
  end

  def title
    MarkdownService.markdown(solr_document.title.first)
  end
end
