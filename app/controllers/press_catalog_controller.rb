# frozen_string_literal: true

class PressCatalogController < ::CatalogController
  before_action :load_press

  configure_blacklight do |config|
    config.search_builder_class = PressSearchBuilder

    config.index.partials = %i[thumbnail index_header]
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
      @press = Press.find_by(subdomain: params['subdomain'])
      return @press unless @press.nil?

      flash[:error] = "The press \"#{params['subdomain']}\" doesn't exist!"
      redirect_to presses_path
    end
end
