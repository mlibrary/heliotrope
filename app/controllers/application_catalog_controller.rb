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
