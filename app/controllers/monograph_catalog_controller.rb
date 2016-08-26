class MonographCatalogController < ::CatalogController
  before_action :load_presenter

  configure_blacklight do |config|
    config.search_builder_class = MonographSearchBuilder

    config.facet_fields.tap do
      # solr facet fields not to be displayed in the index (search results) view
      config.facet_fields.delete('human_readable_type_sim')
      config.facet_fields.delete('creator_full_name_sim')
      config.facet_fields.delete('tag_sim')
      config.facet_fields.delete('subject_sim')
      config.facet_fields.delete('language_sim')
    end

    config.index_fields.tap do
      # solr fields not to be displayed in the index (search results) view
      config.index_fields.delete('creator_full_name_tesim')
      config.index_fields.delete('language_tesim')
      config.index_fields.delete('contributor_tesim')
      config.index_fields.delete('human_readable_type_tesim')
      config.index_fields.delete('copyright_holder_tesim')
      config.index_fields.delete('description_tesim')
      config.index_fields.delete('alt_text_tesim')
      config.index_fields.delete('content_type_tesim')
      config.index_fields.delete('keywords_tesim')
    end

    config.add_facet_field solr_name('section_title', :facetable), label: "Section", url_method: :facet_url_helper, partial: 'custom_section_facet'
    config.add_facet_field solr_name('keywords', :facetable), label: "Keyword", limit: 5, url_method: :facet_url_helper
    config.add_facet_field solr_name('creator_full_name', :facetable), label: 'Creator', limit: 5, url_method: :facet_url_helper
    config.add_facet_field solr_name('resource_type', :facetable), label: "Format", limit: 5, url_method: :facet_url_helper
    config.add_facet_field solr_name('search_year', :facetable), label: "Year", limit: 5, url_method: :facet_url_helper
    config.add_facet_field solr_name('exclusive_to_platform', :facetable), label: "Exclusivity", helper_method: :exclusivity_facet
    config.add_facet_fields_to_solr_request!

    config.index.partials = [:thumbnail, :index_header, :index]
  end

  def facet
    super
  end

  private

    def load_presenter
      @monograph_presenter = CurationConcerns::PresenterFactory.build_presenters([params['id']], CurationConcerns::MonographPresenter, current_ability).first
    end
end
