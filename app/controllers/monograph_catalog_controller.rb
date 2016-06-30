class MonographCatalogController < ::CatalogController
  before_action :load_presenter

  configure_blacklight do |config|
    config.search_builder_class = MonographSearchBuilder

    config.add_facet_field solr_name('keywords', :facetable), label: "Keyword", limit: 5
    config.add_facet_field solr_name('section_title', :facetable), label: "Section", limit: 5
    config.add_facet_fields_to_solr_request!

    config.index.partials = [:index_header, :thumbnail, :index]
  end

  # Override blacklight, controllers/concerns/blacklight/controller.rb
  # For bug #278. TODO: This is probably wrong and should be handled in routes somehow?
  def search_facet_url(options = {})
    opts = search_state.to_h.merge(action: "facet").merge(options).except(:page)
    opts['controller'] = 'catalog'
    url_for opts
  end

  private

    def load_presenter
      @monograph_presenter = CurationConcerns::PresenterFactory.build_presenters([params['id']], CurationConcerns::MonographPresenter, current_ability).first
    end
end
