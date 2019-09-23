# frozen_string_literal: true

module TitlePresenter
  extend ActiveSupport::Concern

  # used as a title starting point by Hyrax::CitationsBehaviors, strip Markdown and HTML tags
  # but note that we purposefully pass a presenter to Hyrax::CitationsBehaviors rather than a Work/Monograph
  def to_s
    MarkdownService.markdown_as_text(md_title, true)
  end

  def page_title
    MarkdownService.markdown_as_text(md_title, true)
  end

  def url_title
    CGI.escape(page_title)
  end

  def title
    MarkdownService.markdown(md_title)
  end

  def embed_code_title
    CGI.escapeHTML(page_title)
  end

  private

    def md_title
      md = solr_document&.title&.first
      md.presence || 'Title'
    end
end
