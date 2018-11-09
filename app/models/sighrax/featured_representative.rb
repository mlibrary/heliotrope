# frozen_string_literal: true

module Sighrax
  class FeaturedRepresentative < Asset
    private_class_method :new

    protected

      def featured_representative
        @featured_representative ||= ::FeaturedRepresentative.find_by(file_set_id: noid)
      end

    private

      def initialize(noid, entity)
        super(noid, entity)
      end
  end
end
