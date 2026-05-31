# frozen_string_literal: true
module ActiveEncode
  class Input
    include Status
    include TechnicalMetadata

    attr_accessor :id
    attr_accessor :url

    def valid?
      id.present? && url.present? &&
        created_at.is_a?(Time) && updated_at.is_a?(Time) &&
        updated_at >= created_at
    end
  end
end
