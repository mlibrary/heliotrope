# frozen_string_literal: true

module EPub
  class ParagraphNullObject < Paragraph
    private_class_method :new

    def html
      '<p></p>'
    end

    private

      def initialize; end
  end
end
