# frozen_string_literal: true

class HtmlToMarkdownService
  def self.convert(html)
    # This is the closest "opposite" conversion I can find to Redcarpet. There are slight whitespace differences.
    ReverseMarkdown.convert(html, github_flavored: true).strip
  end
end
