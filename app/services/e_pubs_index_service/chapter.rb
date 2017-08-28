# frozen_string_literal: true

module EPubsIndexService
  class Chapter
    attr_accessor :book_title, :chapter_id, :href, :basecfi, :body
    def initialize(book_title, chapter_id, href, basecfi, body)
      @book_title = book_title
      @chapter_id = chapter_id
      @href = href
      @basecfi = basecfi
      @body = body
    end
  end
end
