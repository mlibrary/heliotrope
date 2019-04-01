# frozen_string_literal: true

module Fighrax
  class AdminSet < Model
    private_class_method :new

    private

      def initialize(uri, jsonld)
        super(uri, jsonld)
      end
  end
end
