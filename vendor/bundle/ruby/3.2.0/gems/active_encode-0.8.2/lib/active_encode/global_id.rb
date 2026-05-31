# frozen_string_literal: true
require 'globalid'

module ActiveEncode
  module GlobalID
    extend ActiveSupport::Concern
    include ::GlobalID::Identification

    def ==(other)
      other.is_a?(ActiveEncode::Base) && to_global_id == other.to_global_id
    end

    def to_global_id(_options = {})
      super(app: 'ActiveEncode')
    end
  end
end
