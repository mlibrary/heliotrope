# frozen_string_literal: true

module EPub
  class Chapter
    private_class_method :new

    # Class Methods

    def self.null_object
      ChapterNullObject.send(:new)
    end

    # Instance Methods

    def title
      'chapter title'
    end

    def paragraphs
      [Paragraph.send(:new)]
    end

    def presenter
      ChapterPresenter.send(:new, self)
    end

    private

      def initialize; end
  end
end
