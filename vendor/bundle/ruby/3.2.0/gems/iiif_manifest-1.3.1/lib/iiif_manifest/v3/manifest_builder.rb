require_relative 'manifest_builder/iiif_service'
require_relative 'manifest_builder/canvas_builder'
require_relative 'manifest_builder/record_property_builder'
require_relative 'manifest_builder/choice_builder'
require_relative 'manifest_builder/content_builder'
require_relative 'manifest_builder/body_builder'
require_relative 'manifest_builder/structure_builder'
require_relative 'manifest_builder/image_service_builder'
require_relative 'manifest_builder/thumbnail_builder'

module IIIFManifest
  module V3
    class ManifestBuilder
      class << self
        # Utility method to wrap the obj into a IIIF V3 compliant language map as needed.
        def language_map(obj)
          return nil if obj.blank?
          return obj if valid_language_map?(obj)
          obj_to_language_map(obj)
        end

        def valid_language_map?(obj)
          obj.is_a?(Hash) && obj.all? do |k, v|
            k.is_a?(String) && v.is_a?(Array) && v.all? { |o| o.is_a?(String) }
          end
        end

        private

        def obj_to_language_map(obj)
          return nil unless obj.is_a?(String) || (obj.is_a?(Array) && obj.all? { |o| o.is_a?(String) })
          { 'none' => Array(obj) }
        end
      end

      attr_reader :work,
                  :builders,
                  :top_record_factory
      def initialize(work, builders:, top_record_factory:)
        @work = work
        @builders = builders
        @top_record_factory = top_record_factory
      end

      def apply(collection)
        collection['manifests'] ||= []
        collection['manifests'] << to_h
        collection
      end

      def to_h
        @to_h ||= builders.new(work).apply(top_record)
      end

     private

      def top_record
        top_record_factory.new
      end
    end
  end
end
