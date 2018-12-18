# frozen_string_literal: true

module Sighrax
  class Monograph < Model
    private_class_method :new

    def open_access?
      /yes/i.match?(entity['open_access_tesim']&.first)
    end

    def epub_featured_representative
      Sighrax.factory(FeaturedRepresentative.find_by(monograph_id: noid, kind: 'epub')&.file_set_id)
    end

    private

      def initialize(noid, entity)
        super(noid, entity)
      end
  end
end
