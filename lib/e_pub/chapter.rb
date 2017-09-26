# frozen_string_literal: true

module EPub
  class Chapter
    attr_accessor :chapter_id, :chapter_href, :title, :basecfi, :doc, :paragraphs
    private_class_method :new

    # Class Methods

    def self.null_object
      ChapterNullObject.send(:new)
    end

    # Instance Methods
    def title?
      @title.present?
    end

    def paragraphs
      @paragraphs ||= @doc.xpath("//p").map { |p| Paragraph.send(:new, p.text) }
    end

    def presenter
      ChapterPresenter.send(:new, self)
    end

    private

      def initialize(chapter_id, chapter_href, chapter_title, basecfi, doc)
        @chapter_id = chapter_id
        @chapter_href = chapter_href
        @title = chapter_title
        @basecfi = basecfi
        @doc = doc
      end
  end
end
