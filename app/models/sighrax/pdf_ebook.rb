# frozen_string_literal: true

module Sighrax
  class PdfEbook < Ebook
    private_class_method :new

    def watermarkable?
      true
    end

    private

      def initialize(noid, data)
        super(noid, data)
      end
  end
end
