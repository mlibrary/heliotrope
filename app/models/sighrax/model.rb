# frozen_string_literal: true

module Sighrax
  class Model < Entity
    private_class_method :new

    def parent
      Entity.null_entity
    end

    protected

      def model_type
        data['has_model_ssim'].first
      end

    private

      def initialize(noid, data)
        super(noid, data)
      end
  end
end
