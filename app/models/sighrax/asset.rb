# frozen_string_literal: true

module Sighrax
  class Asset < Model
    private_class_method :new

    def parent
      Sighrax.factory(entity['monograph_id_ssim']&.first)
    end

    private

      def initialize(noid, entity)
        super(noid, entity)
      end
  end
end
