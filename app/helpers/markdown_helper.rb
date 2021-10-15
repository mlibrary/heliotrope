# frozen_string_literal: true

module MarkdownHelper
  def render_markdown(value)
    MarkdownService.markdown(value).html_safe # rubocop:disable Rails/OutputSafety
  end

  def render_markdown_as_text(value)
    MarkdownService.markdown_as_text(value).html_safe # rubocop:disable Rails/OutputSafety
  end
end
