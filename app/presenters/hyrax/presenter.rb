# frozen_string_literal: true

module Hyrax
  class Presenter
    private_class_method :new

    attr_reader :noid

    def self.null_presenter(noid = 'null_noid')
      NullPresenter.send(:new, noid)
    end

    private

      def initialize(noid)
        @noid = noid
      end
  end

  class NullPresenter < Presenter
    private_class_method :new

    private

      def initialize(noid)
        super(noid)
      end
  end
end
