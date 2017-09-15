# frozen_string_literal: true

module EPub
  class ChapterPresenter < Presenter
    private_class_method :new

    def title
      @chapter.title
    end

    def paragraphs
      rvalue = []
      @chapter.paragraphs.each do |paragraph|
        rvalue << paragraph.presenter
      end
      rvalue
    end

    private

      def initialize(chapter = Chapter.null_object)
        @chapter = chapter
      end
  end
end
