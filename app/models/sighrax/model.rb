# frozen_string_literal: true

module Sighrax
  class Model < Entity
    private_class_method :new

    protected

      def model_type
        entity['has_model_ssim'].first
      end

    private

      def initialize(noid, entity)
        super(noid, entity)
      end
  end
end
