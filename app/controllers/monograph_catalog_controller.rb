class MonographCatalogController < ::CatalogController
  before_action :load_presenter, only: [:index, :facet]

  configure_blacklight do |config|
    config.search_builder_class = MonographSearchBuilder

    config.default_per_page = 20

    down_arrow = "\u25BC"
    up_arrow = "\u25B2"

    # this will be proper monograph order, I guess we'll still call it Section ordering...
    config.add_sort_field 'section asc', sort: "monograph_position_isi asc", label: "Section #{up_arrow}"
    config.add_sort_field 'section desc', sort: "monograph_position_isi desc", label: "Section #{down_arrow}"

    # leaving the #{uploaded_field} desc in these for section sort when all else is equal
    config.add_sort_field 'format asc', sort: "#{solr_name('resource_type', :sortable)} asc, monograph_position_isi asc", label: "Format #{up_arrow}"
    config.add_sort_field 'format desc', sort: "#{solr_name('resource_type', :sortable)} desc, monograph_position_isi asc", label: "Format #{down_arrow}"
    config.add_sort_field 'year asc', sort: "#{solr_name('search_year', :sortable)} asc, monograph_position_isi asc", label: "Year #{up_arrow}"
    config.add_sort_field 'year desc', sort: "#{solr_name('search_year', :sortable)} desc, monograph_position_isi asc", label: "Year #{down_arrow}"

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
    config.add_facet_field solr_name('content_type', :facetable), label: "Content", show: false
    config.add_facet_field solr_name('resource_type', :facetable), label: "Format", pivot: [solr_name('resource_type', :facetable), solr_name('content_type', :facetable)], url_method: :facet_url_helper
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
