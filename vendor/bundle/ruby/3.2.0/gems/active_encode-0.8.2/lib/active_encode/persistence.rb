# frozen_string_literal: true
require 'active_support'

module ActiveEncode
  module Persistence
    extend ActiveSupport::Concern

    included do
      after_find do |encode|
        persist(persistence_model_attributes(encode))
      end

      around_create do |encode, block|
        create_options = encode.options
        encode = block.call
        persist(persistence_model_attributes(encode, create_options))
      end

      after_cancel do |encode|
        persist(persistence_model_attributes(encode))
      end

      after_reload do |encode|
        persist(persistence_model_attributes(encode))
      end
    end

    private

      def persist(encode_attributes)
        model = ActiveEncode::EncodeRecord.find_or_initialize_by(global_id: encode_attributes[:global_id])
        model.update(encode_attributes) # Don't fail if persisting doesn't succeed?
      end

      def persistence_model_attributes(encode, create_options = nil)
        attributes = {
          global_id: encode.to_global_id.to_s,
          state: encode.state,
          adapter: encode.class.engine_adapter.class.name,
          title: encode.input.url.to_s,
          # Need to ensure that these values come through or else validations will fail
          created_at: encode.created_at,
          updated_at: encode.updated_at,
          raw_object: encode.to_json,
          progress: encode.percent_complete
        }
        attributes[:create_options] = create_options.to_json if create_options.present?
        attributes
      end
  end
end
