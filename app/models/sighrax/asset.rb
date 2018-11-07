# frozen_string_literal: true

module Sighrax
  class Asset < Model
    private_class_method :new

    private

      def initialize(noid, entity)
        super(noid, entity)
      end
  end
end
