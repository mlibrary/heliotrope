class MarkdownService
  mattr_accessor :md
  self.md = Redcarpet::Markdown.new(Redcarpet::Render::HTML.new(safe_links_only: true, hard_wrap: true), autolink: true, strikethrough: true, lax_spacing: true, no_intra_emphasis: true)

  def self.markdown(value)
    rendered_html = md.render(value)
    outer_p_tags_removed = Regexp.new(/\A<p>(.*)<\/p>\Z/m).match(rendered_html)
    rendered_html = outer_p_tags_removed.nil? ? rendered_html : outer_p_tags_removed[1]
    # redcarpet's hard_wrap causes unwanted line breaks, this seems to be the most targeted way to remove them
    rendered_html.gsub(/<\/th><br>/, '</th>')
  end
end
