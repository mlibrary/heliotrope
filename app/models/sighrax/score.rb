# frozen_string_literal: true

module Sighrax
  class Score < Work
    private_class_method :new

    # Including here only what is needed for spec/system/score_file_sets_spec.rb to pass, given that the Score stuff...
    # is mostly dead code at this point.

    def open_access?
      /^yes$/i.match?(scalar('open_access_tesim'))
    end

    def restricted?
      Greensub::Component.find_by(noid: noid).present?
    end

    private

      def initialize(noid, data)
        super(noid, data)
      end
  end
end
