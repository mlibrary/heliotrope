module IIIFManifest
  class ManifestBuilder
    class IIIFService
      attr_reader :inner_hash
      def initialize
        @inner_hash = initial_attributes
      end

      delegate :[]=, :[], :as_json, :to_json, :has_key?, :key?, to: :inner_hash

      def initial_attributes
        {}
      end
    end

    class IIIFManifest < IIIFService
      def label
        inner_hash['label']
      end

      def label=(label)
        inner_hash['label'] = label
      end

      def description=(description)
        return unless description.present?
        inner_hash['description'] = description
      end

      def viewing_hint=(viewing_hint)
        return unless viewing_hint.present?
        inner_hash['viewingHint'] = viewing_hint
      end

      def viewing_direction=(viewing_direction)
        return unless viewing_direction.present?
        inner_hash['viewingDirection'] = viewing_direction
      end

      def viewingDirection
        inner_hash['viewingDirection']
      end

      def sequences
        inner_hash['sequences'] || []
      end

      def sequences=(sequences)
        inner_hash['sequences'] = sequences
      end

      def metadata=(metadata)
        inner_hash['metadata'] = metadata
      end

      def service
        inner_hash['service'] || []
      end

      def service=(service)
        inner_hash['service'] = service
      end

      def see_also=(see_also)
        inner_hash['seeAlso'] = see_also
      end

      def license=(license)
        inner_hash['license'] = license
      end

      def initial_attributes
        {
          '@context' => 'http://iiif.io/api/presentation/2/context.json',
          '@type' => 'sc:Manifest'
        }
      end

      class Collection < IIIFManifest
        def initial_attributes
          {
            '@context' => 'http://iiif.io/api/presentation/2/context.json',
            '@type' => 'sc:Collection'
          }
        end
      end

      class Sequence < IIIFService
        def canvases
          inner_hash['canvases'] || []
        end

        def canvases=(canvases)
          inner_hash['canvases'] = canvases
        end

        def initial_attributes
          {
            '@type' => 'sc:Sequence'
          }
        end
      end

      class Canvas < IIIFService
        def label=(label)
          inner_hash['label'] = label
        end

        def images
          inner_hash['images'] || []
        end

        def images=(images)
          inner_hash['images'] = images
        end

        def initial_attributes
          {
            '@type' => 'sc:Canvas'
          }
        end
      end

      class Range < IIIFService
        def initial_attributes
          {
            '@type' => 'sc:Range'
          }
        end
      end

      class Resource < IIIFService
        def service=(service)
          inner_hash['service'] = service
        end

        def initial_attributes
          {
            '@type' => 'sc:Range'
          }
        end
      end

      class Annotation < IIIFService
        def resource=(resource)
          inner_hash['resource'] = resource
        end

        def resource
          inner_hash['resource']
        end

        def initial_attributes
          {
            '@type' => 'oa:Annotation',
            'motivation' => 'sc:painting'
          }
        end
      end

      class SearchService < IIIFService
        def service=(service)
          inner_hash['service'] = service
        end

        def search_service=(search_service)
          inner_hash['@id'] = search_service
        end

        def initial_attributes
          {
            '@context' => 'http://iiif.io/api/search/0/context.json',
            'profile' => 'http://iiif.io/api/search/0/search',
            'label' => 'Search within this manifest'
          }
        end
      end

      class AutocompleteService < IIIFService
        def autocomplete_service
          inner_hash['@id']
        end

        def autocomplete_service=(autocomplete_service)
          inner_hash['@id'] = autocomplete_service
        end

        def initial_attributes
          {
            'profile' => 'http://iiif.io/api/search/0/autocomplete',
            'label' => 'Get suggested words in this manifest'
          }
        end
      end
    end
  end
end
