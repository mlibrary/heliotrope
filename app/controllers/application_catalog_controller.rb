# frozen_string_literal: true

class ApplicationCatalogController < ApplicationController
  include Hydra::Catalog
  include Hydra::Controller::ControllerBehavior

  # Ensure view lookups for subclasses (e.g. PressCatalogController,
  # MonographCatalogController) fall back to app/views/catalog/ for shared
  # Blacklight/Hyrax partials such as `_helio_results_sr_only_div`,
  # `_search_results`, `_zero_results`, etc. Without this, removing the
  # inheritance from CatalogController breaks partial resolution.
  def self.local_prefixes
    super + ['catalog']
  end

  # This filter applies the hydra access controls
  before_action :enforce_show_permissions, only: :show
  before_action :search_ongoing

  # Baseline Blacklight configuration shared by all catalog controllers
  # (CatalogController, PressCatalogController, MonographCatalogController).
  # This used to live only in CatalogController and be inherited; with the
  # children now standalone we need to provide it here so search actually
  # has a queryable `qf`, results can resolve their per-document partial
  # via `display_type_field`, and titles/thumbnails render. Catalog-specific
  # facets, index fields, search fields and OAI configuration remain in
  # CatalogController; per-press/per-monograph specifics remain in their
  # respective controllers.
  configure_blacklight do |config|
    ## Default parameters to send to solr for all search-like requests. See also SolrHelper#solr_search_params
    config.default_solr_params = {
      qf: 'title_tesim creator_tesim creator_full_name_tesim creator_display_tesim subject_tesim description_tesim keyword_tesim contributor_tesim caption_tesim transcript_tesim translation_tesim alt_text_tesim identifier_tesim identifier_ssim isbn_numeric table_of_contents_tesim doi_ssim doi_url_ssim',
      qt: 'search',
      rows: 10
    }

    # solr field configuration for search results/index views
    config.index.title_field = solr_name('title', :stored_searchable)
    config.index.display_type_field = solr_name('has_model', :symbol)
    config.index.thumbnail_field = 'thumbnail_path_ss'

    # Blacklight 7 results-collection tools (sort, per-page, view switcher)
    config.add_results_collection_tool(:sort_widget)
    config.add_results_collection_tool(:per_page_widget)
    config.add_results_collection_tool(:view_type_group)
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

  def search_ongoing
    @search_ongoing = false

    params.each do |key, _value|
      non_search_keys = ['action', 'authenticity_token', 'controller', 'id', 'locale', 'page', 'per_page', 'press', 'sort', 'utf8', 'view']
      if non_search_keys.exclude? key
        @search_ongoing = true
        break
      end
    end
  end
end
