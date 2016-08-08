class MonographCatalogController < ::CatalogController
  before_action :load_presenter

  configure_blacklight do |config|
    config.search_builder_class = MonographSearchBuilder

    config.facet_fields.tap do
      config.facet_fields.delete('human_readable_type_sim')
    end

    config.add_facet_field solr_name('resource_type', :facetable), label: "Resource Type", limit: 5
    config.add_facet_field solr_name('keywords', :facetable), label: "Keyword", limit: 5
    config.add_facet_field solr_name('section_title', :facetable), label: "Section", limit: 5, sort: 'index'
    config.add_facet_field solr_name('sort_date', :facetable), date: { format: '%Y' }, label: "Year", limit: 5
    config.add_facet_field solr_name('exclusive_to_platform', :facetable), label: "Exclusivity", helper_method: :exclusivity_facet
    config.add_facet_fields_to_solr_request!

    config.index.partials = [:index_header, :thumbnail, :index]
  end

  def facet
    super
  end

  private

    def load_presenter
      @monograph_presenter = CurationConcerns::PresenterFactory.build_presenters([params['id']], CurationConcerns::MonographPresenter, current_ability).first
    end
end
