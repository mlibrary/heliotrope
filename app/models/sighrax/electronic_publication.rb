# frozen_string_literal: true

module Sighrax
  class ElectronicPublication < Asset
    private_class_method :new

    private
      def initialize(noid, data)
        super(noid, data)
      end
  end
end
