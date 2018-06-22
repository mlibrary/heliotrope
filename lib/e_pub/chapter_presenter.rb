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
      @chapter.href
    end

    def cfi
      @chapter.basecfi
    end

    def downloadable?
      @chapter.downloadable?
    end

    private

      def initialize(chapter = Chapter.null_object)
        @chapter = chapter
      end
  end
end
