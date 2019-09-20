# frozen_string_literal: true

module Sighrax
  class Monograph < Model
    private_class_method :new

    def children
      Array(data['ordered_member_ids_ssim']).map { |noid| Sighrax.factory(noid) }
    end

    def epub_featured_representative
      Sighrax.factory(FeaturedRepresentative.find_by(work_id: noid, kind: 'epub')&.file_set_id)
    end

    private
      def initialize(noid, data)
        super(noid, data)
      end
  end
end
