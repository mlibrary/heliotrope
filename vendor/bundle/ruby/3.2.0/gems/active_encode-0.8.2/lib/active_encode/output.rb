# frozen_string_literal: true
module ActiveEncode
  class Output
    include Status
    include TechnicalMetadata

    attr_accessor :id
    attr_accessor :url
    attr_accessor :label

    def valid?
      id.present? && url.present? && label.present? &&
        created_at.is_a?(Time) && updated_at.is_a?(Time) &&
        updated_at >= created_at
    end
  end
end
