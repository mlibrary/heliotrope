# frozen_string_literal: true

module Fighrax
  class Model < Node
    private_class_method :new

    def model
      raise(StandardError, 'hasModel is blank') if super.blank?
      super
    end

    private

      def initialize(uri, jsonld)
        super(uri, jsonld)
      end
  end
end
