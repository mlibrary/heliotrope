# frozen_string_literal: true

module EPub
  class Paragraph
    private_class_method :new

    # Class Methods

    def self.null_object
      ParagraphNullObject.send(:new)
    end

    # Instance Methods

    def html
      '<p>paragraph</p>'
    end

    def presenter
      ParagraphPresenter.send(:new, self)
    end

    private

      def initialize; end
  end
end
