# frozen_string_literal: true

module Sighrax
  class Model < Entity
    private_class_method :new

    attr_reader :presenter

    protected

      def model_type
        Array(data['has_model_ssim']).first
      end

    private

      def initialize(noid, data)
        super(noid, data)
        @presenter = self.class.null_entity
      end
  end
end
