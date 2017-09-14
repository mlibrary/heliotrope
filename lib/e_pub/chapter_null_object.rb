# frozen_string_literal: true

module EPub
  class ChapterNullObject < Chapter
    private_class_method :new

    def title
      ''
    end

    def paragraphs
      []
    end

    private

      def initialize; end
  end
end
