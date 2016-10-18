module MarkdownHelper
  def render_markdown(value)
    MarkdownService.markdown(value).html_safe
  end

  def render_markdown_as_text(value)
    MarkdownService.markdown_as_text(value).html_safe
  end
end
