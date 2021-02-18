# frozen_string_literal: true

module Sighrax
  class PortableDocumentFormat < ElectronicBook
    private_class_method :new

    delegate :products, to: :monograph

    def monograph
      parent
    end

    private

      def initialize(noid, data)
        super(noid, data)
      end
  end
end
