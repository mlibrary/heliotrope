# frozen_string_literal: true

module Sighrax
  class Monograph < Model
    private_class_method :new

    def epub_featured_representative
      Sighrax.factory(FeaturedRepresentative.find_by(monograph_id: noid, kind: 'epub')&.file_set_id)
    end

    private

      def initialize(noid, data)
        super(noid, data)
      end
  end
end
