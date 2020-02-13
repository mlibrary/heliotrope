# frozen_string_literal: true

module Sighrax
  class Monograph < Work
    private_class_method :new

    def epub_featured_representative
      Sighrax.from_noid(FeaturedRepresentative.find_by(work_id: noid, kind: 'epub')&.file_set_id)
    end

    def pdf_ebook_featured_representative
      Sighrax.from_noid(FeaturedRepresentative.find_by(work_id: noid, kind: 'pdf_ebook')&.file_set_id)
    end

    private

      def initialize(noid, data)
        super(noid, data)
      end
  end
end
