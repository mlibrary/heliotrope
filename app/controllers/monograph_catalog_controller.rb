class MonographCatalogController < ::CatalogController
  before_action :load_presenter, only: [:index, :facet]

  configure_blacklight do |config|
    config.search_builder_class = MonographSearchBuilder

    config.default_per_page = 20
    config.add_sort_field 'chapter asc', sort: "#{uploaded_field} desc", label: "Chapter \u25B2"
    config.add_sort_field 'chapter desc', sort: "#{uploaded_field} asc", label: "Chapter \u25BC"
    # leaving the #{uploaded_field} desc in these for chapter sort when all else is equal
    config.add_sort_field 'format asc', sort: "#{solr_name('resource_type', :sortable)} asc, #{uploaded_field} desc", label: "Format \u25B2"
    config.add_sort_field 'format desc', sort: "#{solr_name('resource_type', :sortable)} desc, #{uploaded_field} desc", label: "Format \u25BC"
    config.add_sort_field 'year asc', sort: "#{solr_name('search_year', :sortable)} asc, #{uploaded_field} desc", label: "Year \u25B2"
    config.add_sort_field 'year desc', sort: "#{solr_name('search_year', :sortable)} desc, #{uploaded_field} desc", label: "Year \u25BC"

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

    config.add_facet_field solr_name('section_title', :facetable),
                           label: "Section", url_method: :facet_url_helper,
                           partial: 'custom_section_facet',
                           helper_method: :markdown_as_text_facet
    config.add_facet_field solr_name('keywords', :facetable), label: "Keyword", limit: 5, url_method: :facet_url_helper
    config.add_facet_field solr_name('creator_full_name', :facetable), label: 'Creator', limit: 5, url_method: :facet_url_helper
    config.add_facet_field solr_name('resource_type', :facetable), label: "Format", limit: 5, url_method: :facet_url_helper
    config.add_facet_field solr_name('search_year', :facetable), label: "Year", limit: 5, url_method: :facet_url_helper
    config.add_facet_field solr_name('exclusive_to_platform', :facetable), label: "Exclusivity", helper_method: :exclusivity_facet
    config.add_facet_fields_to_solr_request!

    config.index.partials = [:thumbnail, :index_header, :index]

    config.view.gallery.partials = [:index_header, :index]
  end

  def facet
    super
  end

  private

    def load_presenter
      monograph_id = params[:monograph_id] || params[:id]
      @curation_concern = Monograph.find(monograph_id)
      @monograph_presenter = CurationConcerns::PresenterFactory.build_presenters([monograph_id], CurationConcerns::MonographPresenter, current_ability).first
    end
end
