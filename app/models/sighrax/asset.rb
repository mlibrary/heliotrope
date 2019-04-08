# frozen_string_literal: true

module Sighrax
  class Asset < Model
    private_class_method :new

    def parent
      Sighrax.factory(Array(data['monograph_id_ssim']).first)
    end

    private

      def initialize(noid, data)
        super(noid, data)
        @presenter = Hyrax::PresenterFactory.build_for(ids: [noid], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil)&.first || self.class.null_entity
      end
  end
end
