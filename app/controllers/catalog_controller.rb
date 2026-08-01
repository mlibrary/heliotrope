# frozen_string_literal: true

class CatalogController < ApplicationCatalogController
  include BlacklightOaiProvider::Controller
  # Shared full-catalog config (search builder, index/search fields). This is
  # shared with AdminCatalogController, which is a sibling (both inherit
  # ApplicationCatalogController) rather than a subclass of this controller.
  include FullCatalogBehavior
  # The full catalog is not yet a public-facing feature. For now, keep the
  # browsing UI (index/facet) behind platform admin login. The OAI provider
  # actions remain publicly accessible. When the public catalog ships, remove
  # this include; because AdminCatalogController includes the gate separately,
  # that will not accidentally expose the admin catalog.
  include PlatformAdminGate

  configure_blacklight do |config|
    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display
    config.add_facet_field solr_name('human_readable_type', :facetable), label: 'Type', limit: 5
    config.add_facet_field solr_name('creator', :facetable), label: 'Author', limit: 5, url_method: :facet_url_helper
    config.add_facet_field solr_name('tag', :facetable), label: 'Tag', limit: 5
    config.add_facet_field solr_name('subject', :facetable), label: 'Subject', limit: 5
    config.add_facet_field solr_name('language', :facetable), label: 'Language', limit: 5, url_method: :facet_url_helper
    config.add_facet_field solr_name('based_near', :facetable), label: 'Near', limit: 5
    # config.add_facet_field solr_name('publisher', :facetable), limit: 5
    # config.add_facet_field solr_name('file_format', :facetable), limit: 5
    config.add_facet_field 'press_name_ssim', label: 'Publisher', limit: 5
    config.add_facet_field 'generic_type_sim', show: false, single: true

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.add_facet_fields_to_solr_request!


    # Oai Configuration
    config.oai = {
      provider: {
        repository_name: 'Fulcrum',
        repository_url: 'https://www.fulcrum.org/catalog/oai',
        record_prefix: 'oai:fulcrum.org',
        admin_email: 'fulcrum-info@umich.edu',
        sample_id: '9s1616317'
      },
      document: {
        limit: 50,
        set_model: OaiPressSet,
        set_fields: [{ label: 'Press', solr_field: 'press_name_ssim' }]
      }
    }
  end
end
