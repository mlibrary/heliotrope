# frozen_string_literal: true

module Sighrax
  class Work < Model
    private_class_method :new

    def children
      Array(data['ordered_member_ids_ssim']).map { |noid| Sighrax.from_noid(noid) }
    end

    private

      def initialize(noid, data)
        super(noid, data)
      end
  end
end
