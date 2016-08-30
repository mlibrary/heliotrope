class MarkdownService
  mattr_accessor :md
  self.md = Redcarpet::Markdown.new(Redcarpet::Render::HTML.new(safe_links_only: true, hard_wrap: true),
                                    autolink: true, strikethrough: true, lax_spacing: true, no_intra_emphasis: true,
                                    disable_indented_code_blocks: true, tables: true)

  def self.markdown(value)
    rendered_html = md.render(value)
    outer_p_tags_removed = Regexp.new(/\A<p>(.*)<\/p>\Z/m).match(rendered_html)
    rendered_html = outer_p_tags_removed.nil? ? rendered_html : outer_p_tags_removed[1]
    # redcarpet's hard_wrap causes unwanted line breaks, the first gsub seems to be the most targeted way to remove them
    # with the second gsub allowing us to unescape non-breaking spaces to format certain fields per authors' requests
    rendered_html.gsub(/<\/th><br>/, '</th>').gsub(/&amp;nbsp;/, '&nbsp;')
  end
end
