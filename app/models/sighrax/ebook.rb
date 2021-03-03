# frozen_string_literal: true

module Sighrax
  class Ebook < Asset
    private_class_method :new

    delegate :open_access?, :_press, :products, :tombstone?, :unrestricted?, to: :monograph

    def monograph
      parent
    end

    private

      def initialize(noid, data)
        super(noid, data)
      end
  end
end
