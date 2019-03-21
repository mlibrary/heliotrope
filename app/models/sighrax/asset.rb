# frozen_string_literal: true

module Sighrax
  class Asset < Model
    private_class_method :new

    def parent
      Sighrax.factory(data['monograph_id_ssim']&.first)
    end

    private

      def initialize(noid, data)
        super(noid, data)
      end
  end
end
