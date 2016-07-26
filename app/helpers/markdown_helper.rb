module MarkdownHelper
  def render_markdown(value)
    MarkdownService.markdown(value).html_safe
  end
end
