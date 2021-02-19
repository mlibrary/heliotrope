# frozen_string_literal: true

module Sighrax
  class PortableDocumentFormat < ElectronicBook
    private_class_method :new

    delegate :products, :open_access?, :restricted?, :tombstone?, to: :monograph

    def monograph
      parent
    end

    def watermarkable?
      Array(data['external_resource_url_ssim']).first.blank?
    end

    private

      def initialize(noid, data)
        super(noid, data)
      end
  end
end
