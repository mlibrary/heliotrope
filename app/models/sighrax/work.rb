# frozen_string_literal: true

module Sighrax
  class Work < Model
    private_class_method :new

    def children
      children_noids.map { |noid| Sighrax.from_noid(noid) }
    end

    def children_noids
      Array(data['ordered_member_ids_ssim'])
    end

    private

      def initialize(noid, data)
        super(noid, data)
      end
  end
end
