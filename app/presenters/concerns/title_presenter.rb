# frozen_string_literal: true

module TitlePresenter
  extend ActiveSupport::Concern

  # used as a title starting point by Hyrax::CitationsBehaviors, strip Markdown and HTML tags
  def to_s
    MarkdownService.markdown_as_text(md_title, true)
  end

  def page_title
    to_s
  end

  def title
    MarkdownService.markdown(md_title)
  end

  private

    def md_title
      md = solr_document&.title&.first
      md.presence || 'Title'
    end
end
