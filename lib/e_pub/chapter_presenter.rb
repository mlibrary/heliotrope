# frozen_string_literal: true

module EPub
  class ChapterPresenter < Presenter
    private_class_method :new

    def title
      @chapter.title
    end

    def paragraphs
      @chapter.paragraphs.map(&:presenter)
    end

    def href
      @chapter.chapter_href
    end

    def cfi
      @chapter.basecfi
    end

    def blurb
      text = ""
      @chapter.paragraphs.each do |p|
        text += "<p>#{p.text}</p>"
        break if text.length >= 100
      end
      text.html_safe # rubocop:disable Rails/OutputSafety
    end

    private

      def initialize(chapter = Chapter.null_object)
        @chapter = chapter
      end
  end
end
