# frozen_string_literal: true

class CatalogController < ApplicationController
  include Hydra::Catalog
  include Hydra::Controller::ControllerBehavior

  # This filter applies the hydra access controls
  before_action :enforce_show_permissions, only: :show

  def self.uploaded_field
    solr_name('system_create', :stored_sortable, type: :date)
  end

  def self.modified_field
    solr_name('system_modified', :stored_sortable, type: :date)
  end

  configure_blacklight do |config|
    config.search_builder_class = ::SearchBuilder
    ## Default parameters to send to solr for all search-like requests. See also SolrHelper#solr_search_params
    config.default_solr_params = {
      qf: 'title_tesim creator_full_name_tesim creator_display_tesim subject_tesim description_tesim keywords_tesim contributor_tesim caption_tesim transcript_tesim translation_tesim alt_text_tesim primary_editor_full_name_tesim editor_tesim',
      qt: 'search',
      rows: 10
    }

    # solr field configuration for search results/index views
    config.index.title_field = solr_name('title', :stored_searchable)
    config.index.display_type_field = solr_name('has_model', :symbol)

    config.index.thumbnail_field = 'thumbnail_path_ss'
    config.index.partials.delete(:thumbnail) # we render this inside _index_default.html.erb
    config.index.partials += [:action_menu]

    # solr field configuration for document/show views
    # config.show.title_field = solr_name("title", :stored_searchable)
    # config.show.display_type_field = solr_name("has_model", :symbol)

    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display
    config.add_facet_field solr_name('human_readable_type', :facetable)
    config.add_facet_field solr_name('creator_full_name', :facetable), label: 'Author', limit: 5, url_method: :facet_url_helper
    config.add_facet_field solr_name('tag', :facetable), limit: 5
    config.add_facet_field solr_name('subject', :facetable), limit: 5
    config.add_facet_field solr_name('language', :facetable), limit: 5, url_method: :facet_url_helper
    config.add_facet_field solr_name('based_near', :facetable), limit: 5
    # config.add_facet_field solr_name('publisher', :facetable), limit: 5
    # config.add_facet_field solr_name('file_format', :facetable), limit: 5
    config.add_facet_field 'press_name_ssim', label: "Publisher", limit: 5
    config.add_facet_field 'generic_type_sim', show: false, single: true

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.add_facet_fields_to_solr_request!

    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display
    config.add_index_field solr_name('description', :stored_searchable)
    config.add_index_field solr_name('tag', :stored_searchable)
    config.add_index_field solr_name('subject', :stored_searchable)
    config.add_index_field solr_name('creator_full_name', :stored_searchable), label: 'Creator'
    config.add_index_field solr_name('contributor', :stored_searchable)
    config.add_index_field solr_name('publisher', :stored_searchable)
    config.add_index_field solr_name('based_near', :stored_searchable)
    config.add_index_field solr_name('language', :stored_searchable)
    config.add_index_field solr_name('date_uploaded', :stored_sortable)
    config.add_index_field solr_name('date_modified', :stored_sortable)
    config.add_index_field solr_name('date_created', :stored_searchable)
    config.add_index_field solr_name("rights_statement", :stored_searchable)
    config.add_index_field solr_name("license", :stored_searchable)
    config.add_index_field solr_name('human_readable_type', :stored_searchable)
    config.add_index_field solr_name('format', :stored_searchable)
    config.add_index_field solr_name('identifier', :stored_searchable)
    # Heliotrope
    config.add_index_field solr_name('date_published', :stored_searchable)
    config.add_index_field solr_name('isbn', :stored_searchable)
    config.add_index_field solr_name('editor', :stored_searchable)
    config.add_index_field solr_name('copyright_holder', :stored_searchable)
    config.add_index_field solr_name('buy_url', :symbol)
    config.add_index_field solr_name('caption', :stored_searchable)
    config.add_index_field solr_name('alt_text', :stored_searchable)
    config.add_index_field solr_name('content_type', :stored_searchable)
    config.add_index_field solr_name('keywords', :stored_searchable)
    config.add_index_field solr_name('section_title', :stored_searchable)

    # "fielded" search configuration. Used by pulldown among other places.
    # For supported keys in hash, see rdoc for Blacklight::SearchFields
    #
    # Search fields will inherit the :qt solr request handler from
    # config[:default_solr_parameters], OR can specify a different one
    # with a :qt key/value. Below examples inherit, except for subject
    # that specifies the same :qt as default for our own internal
    # testing purposes.
    #
    # The :key is what will be used to identify this BL search field internally,
    # as well as in URLs -- so changing it after deployment may break bookmarked
    # urls.  A display label will be automatically calculated from the :key,
    # or can be specified manually to be different.
    #
    # This one uses all the defaults set by the solr request handler. Which
    # solr request handler? The one set in config[:default_solr_parameters][:qt],
    # since we aren't specifying it otherwise.
    config.add_search_field('all_fields', label: 'All Fields', include_in_advanced_search: false) do |field|
      title_name = solr_name('title', :stored_searchable, type: :string)
      label_name = solr_name('title', :stored_searchable, type: :string)
      contributor_name = solr_name('contributor', :stored_searchable, type: :string)
      field.solr_parameters = {
        qf: "#{title_name} #{label_name} file_format_tesim #{contributor_name}",
        pf: title_name.to_s
      }
    end

    # Now we see how to over-ride Solr request handler defaults, in this
    # case for a BL "search field", which is really a dismax aggregate
    # of Solr search fields.
    # creator, title, description, publisher, date_created,
    # subject, language, resource_type, format, identifier, based_near,
    config.add_search_field('contributor') do |field|
      # solr_parameters hash are sent to Solr as ordinary url query params.

      # :solr_local_parameters will be sent using Solr LocalParams
      # syntax, as eg {! qf=$title_qf }. This is neccesary to use
      # Solr parameter de-referencing like $title_qf.
      # See: http://wiki.apache.org/solr/LocalParams
      solr_name = solr_name('contributor', :stored_searchable, type: :string)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('creator') do |field|
      solr_name = solr_name('creator_full_name', :stored_searchable, type: :string)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('title') do |field|
      solr_name = solr_name('title', :stored_searchable, type: :string)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('description') do |field|
      field.label = 'Abstract or Summary'
      solr_name = solr_name('description', :stored_searchable, type: :string)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('publisher') do |field|
      solr_name = solr_name('publisher', :stored_searchable, type: :string)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('date_created') do |field|
      solr_name = solr_name('created', :stored_searchable, type: :string)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('subject') do |field|
      solr_name = solr_name('subject', :stored_searchable, type: :string)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('language') do |field|
      solr_name = solr_name('language', :stored_searchable, type: :string)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('human_readable_type') do |field|
      solr_name = solr_name('human_readable_type', :stored_searchable, type: :string)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('format') do |field|
      field.include_in_advanced_search = false
      solr_name = solr_name('format', :stored_searchable, type: :string)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('identifier') do |field|
      field.include_in_advanced_search = false
      solr_name = solr_name('id', :stored_searchable, type: :string)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('based_near') do |field|
      field.label = 'Location'
      solr_name = solr_name('based_near', :stored_searchable, type: :string)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('tag') do |field|
      solr_name = solr_name('tag', :stored_searchable, type: :string)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('depositor') do |field|
      solr_name = solr_name('depositor', :stored_searchable, type: :string)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('rights_statement') do |field|
      solr_name = solr_name("rights_statement", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('license') do |field|
      solr_name = solr_name('license', :stored_searchable, type: :string)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    # If there are more than this many search results, no spelling ("did you mean") suggestion is offered.
    config.spell_max = 5
  end

  def show_site_search?
    true
  end

  # disable the bookmark control from displaying in gallery view
  # Hyrax doesn't show any of the default controls on the list view, so
  # this method is not called in that context.
  def render_bookmarks_control?
    false
  end
end
