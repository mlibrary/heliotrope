# frozen_string_literal: true

module EPub
  class Paragraph
    private_class_method :new
    attr_accessor :text

    # Class Methods

    def self.null_object
      ParagraphNullObject.send(:new)
    end

    # Instance Methods

    def presenter
      ParagraphPresenter.send(:new, self)
    end

    private

      def initialize(text)
        @text = text
      end
  end

  class ParagraphNullObject < Paragraph
    private_class_method :new

    def html
      '<p></p>'
    end

    private

      def initialize; end
  end
end
