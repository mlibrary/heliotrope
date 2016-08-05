class MarkdownService
  mattr_accessor :md
  self.md = Redcarpet::Markdown.new(Redcarpet::Render::HTML.new(safe_links_only: true), autolink: true, strikethrough: true, lax_spacing: true, no_intra_emphasis: true)

  def self.markdown(value)
    rendered_html = md.render(value)
    outer_p_tags_removed = Regexp.new(/\A<p>(.*)<\/p>\Z/m).match(rendered_html)
    outer_p_tags_removed.nil? ? rendered_html : outer_p_tags_removed[1]
  end
end
