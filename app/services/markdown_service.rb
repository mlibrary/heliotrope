require 'redcarpet/render_strip'

class CustomMarkdownRenderer < Redcarpet::Render::HTML
  def link(link, _title, link_text)
    if external_link?(link)
      "<a target=\"_blank\" href=\"#{link}\">#{link_text}</a>"
    else
      "<a href=\"#{link}\">#{link_text}</a>"
    end
  end

  def autolink(link, _link_type)
    if external_link?(link)
      "<a target=\"_blank\" href=\"#{link}\">#{link}</a>"
    else
      "<a href=\"#{link}\">#{link}</a>"
    end
  end

  private

    def external_link?(link)
      if link.start_with?('/') ||
         link.include?('fulcrum.org') ||
         link.include?('fulcrumscholar.org') ||
         link.include?('fulcrum.www.lib.umich.edu') ||
         link.include?('localhost')
        false
      else
        true
      end
    end
end

class MarkdownService
  mattr_accessor :md

  render_options = {
    hard_wrap:                    true,
    safe_links_only:              true
  }

  extensions = {
    autolink:                     true,
    disable_indented_code_blocks: true,
    lax_spacing:                  true,
    no_intra_emphasis:            true,
    strikethrough:                true,
    tables:                       true
  }

  self.md = Redcarpet::Markdown.new(CustomMarkdownRenderer.new(render_options), extensions)

  def self.markdown(value)
    rendered_html = md.render(value)
    outer_p_tags_removed = Regexp.new(/\A<p>(.*)<\/p>\Z/m).match(rendered_html)
    rendered_html = outer_p_tags_removed.nil? ? rendered_html : outer_p_tags_removed[1]
    # redcarpet's hard_wrap causes unwanted line breaks, the first gsub seems to be the most targeted way to remove them
    # with the second gsub allowing us to unescape non-breaking spaces to format certain fields per authors' requests
    rendered_html.gsub(/<\/th><br>/, '</th>').gsub(/&amp;nbsp;/, '&nbsp;').html_safe
  end

  mattr_accessor :sd
  self.sd = Redcarpet::Markdown.new(Redcarpet::Render::StripDown.new, strikethrough: true, escape_html: false)

  def self.markdown_as_text(value)
    sd.render(value).gsub(/\n$/, '').tr("\n", ' ')
  end
end
