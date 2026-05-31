module IIIFManifest
  module V3
    class ManifestBuilder
      class IIIFService < IIIFManifest::ManifestBuilder::IIIFService
      end

      class IIIFManifest < IIIFService
        def label
          inner_hash['label']
        end

        def label=(label)
          inner_hash['label'] = label
        end

        def summary
          inner_hash['summary']
        end

        def summary=(summary)
          return unless summary.present?
          inner_hash['summary'] = summary
        end

        def behavior=(behavior)
          return unless behavior.present?
          inner_hash['behavior'] = behavior
        end

        def viewing_direction=(viewing_direction)
          return unless viewing_direction.present?
          inner_hash['viewingDirection'] = viewing_direction
        end

        def viewingDirection
          inner_hash['viewingDirection']
        end

        def items
          inner_hash['items'] ||= []
        end

        def items=(items)
          inner_hash['items'] = items
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

        def rendering=(rendering)
          inner_hash['rendering'] = rendering
        end

        def rights=(rights)
          inner_hash['rights'] = Array(rights).first
        end

        def homepage=(homepage)
          inner_hash['homepage'] = homepage
        end

        def thumbnail=(thumbnail)
          inner_hash['thumbnail'] = thumbnail
        end

        def initial_attributes
          {
            '@context' => [
              'http://www.w3.org/ns/anno.jsonld',
              'http://iiif.io/api/presentation/3/context.json'
            ],
            'type' => 'Manifest'
          }
        end

        class Collection < IIIFManifest
          def initial_attributes
            {
              '@context' => [
                'http://www.w3.org/ns/anno.jsonld',
                'http://iiif.io/api/presentation/3/context.json'
              ],
              'type' => 'Collection'
            }
          end

          def viewing_direction=(_viewing_direction)
            raise NotImplementedError
          end

          def viewingDirection
            raise NotImplementedError
          end
        end

        class Canvas < IIIFService
          def label
            inner_hash['label']
          end

          def label=(label)
            inner_hash['label'] = label
          end

          def items
            inner_hash['items'] ||= []
          end

          def items=(items)
            inner_hash['items'] = items
          end

          def thumbnail
            inner_hash['thumbnail']
          end

          def thumbnail=(thumbnail)
            inner_hash['thumbnail'] = thumbnail
          end

          def initial_attributes
            {
              'type' => 'Canvas'
            }
          end

          def rendering=(rendering)
            inner_hash['rendering'] = rendering
          end
        end

        class Range < IIIFService
          def initial_attributes
            {
              'type' => 'Range'
            }
          end
        end

        class Body < IIIFService
          def service=(service)
            inner_hash['service'] = service
          end

          def initial_attributes
            {
            }
          end
        end

        class Choice < IIIFService
          def items
            inner_hash['items'] ||= []
          end

          def items=(items)
            inner_hash['items'] = items
          end

          def initial_attributes
            {
              'type' => 'Choice',
              'choiceHint' => 'user'
            }
          end
        end

        class AnnotationPage < IIIFService
          def items
            inner_hash['items'] ||= []
          end

          def items=(items)
            inner_hash['items'] = items
          end

          def index
            @index ||= SecureRandom.uuid
          end

          def initial_attributes
            {
              'type' => 'AnnotationPage'
            }
          end
        end

        class Annotation < IIIFService
          def body=(body)
            inner_hash['body'] = body
          end

          def body
            inner_hash['body']
          end

          def index
            @index ||= SecureRandom.uuid
          end

          def initial_attributes
            {
              'type' => 'Annotation',
              'motivation' => 'painting'
            }
          end
        end

        class SearchService < IIIFService
          def service=(service)
            inner_hash['service'] = service
          end

          def search_service=(search_service)
            inner_hash['id'] = search_service
          end

          def initial_attributes
            {
              '@context' => 'http://iiif.io/api/search/1/context.json',
              'profile' => 'http://iiif.io/api/search/1/search',
              'label' => 'Search within this manifest',
              'type' => 'SearchService1'
            }
          end
        end

        class AutocompleteService < IIIFService
          def autocomplete_service
            inner_hash['id']
          end

          def autocomplete_service=(autocomplete_service)
            inner_hash['id'] = autocomplete_service
          end

          def initial_attributes
            {
              'profile' => 'http://iiif.io/api/search/1/autocomplete',
              'label' => 'Get suggested words in this manifest',
              'type' => 'AutoCompleteService1'
            }
          end
        end

        class Thumbnail < IIIFService
          def service=(service)
            inner_hash['service'] = service
          end

          def initial_attributes
            {
            }
          end
        end
      end
    end
  end
end
