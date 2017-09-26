# frozen_string_literal: true

module MCSV
  class ManifestNullObject < Manifest
    private_class_method :new

    private

      def initialize; end
  end
end
