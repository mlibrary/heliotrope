class PressCatalogController < ::CatalogController
  before_action :load_press

  configure_blacklight do |config|
    config.search_builder_class = PressSearchBuilder
  end

  def show_site_search?
    false
  end

  # The search box should scope the search results to the
  # current press, not a site-wide search.
  def show_press_search?
    true
  end
  helper_method :show_press_search?

  def facet
    super
  end

  private

    def load_press
      @press = Press.find_by_subdomain(params['subdomain'])
    end
end
