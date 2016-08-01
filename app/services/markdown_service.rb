class MarkdownService
  mattr_accessor :md
  self.md = Redcarpet::Markdown.new(Redcarpet::Render::HTML.new(safe_links_only: true), strikethrough: true, lax_spacing: true, no_intra_emphasis: true)

  def self.markdown(value)
    md.render(value).gsub(/^<p>/, "").gsub(/<\/p>$/, "")
  end
end
