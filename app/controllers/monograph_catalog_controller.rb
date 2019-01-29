# frozen_string_literal: true

class MonographCatalogController < ::CatalogController
  before_action :load_presenter, only: %i[index facet]
  after_action :add_counter_stat, only: %i[index]

  self.theme = 'curation_concerns'
  with_themed_layout 'catalog'

  configure_blacklight do |config|
    config.search_builder_class = MonographSearchBuilder

    config.default_per_page = 20
    config.add_sort_field 'relevance', sort: "score desc, monograph_position_isi asc", label: "Relevance"
    config.add_sort_field 'section asc', sort: "monograph_position_isi asc", label: "Section (Earliest First)"
    config.add_sort_field 'section desc', sort: "monograph_position_isi desc", label: "Section (Last First)"
    # leaving the #{uploaded_field} desc in these for section sort when all else is equal
    config.add_sort_field 'format asc', sort: "#{solr_name('resource_type', :sortable)} asc, monograph_position_isi asc", label: "Format (A-Z)"
    config.add_sort_field 'format desc', sort: "#{solr_name('resource_type', :sortable)} desc, monograph_position_isi asc", label: "Format (Z-A)"
    config.add_sort_field 'year asc', sort: "#{solr_name('search_year', :sortable)} asc, monograph_position_isi asc", label: "Year (Oldest First)"
    config.add_sort_field 'year desc', sort: "#{solr_name('search_year', :sortable)} desc, monograph_position_isi asc", label: "Year (Newest First)"

    config.facet_fields.tap do
      # solr facet fields not to be displayed in the index (search results) view
      config.facet_fields.delete('human_readable_type_sim')
      config.facet_fields.delete('creator_sim')
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
      config.index_fields.delete('section_title_tesim')
      config.index_fields.delete('license_tesim')
    end

    config.add_facet_field solr_name('section_title', :facetable),
                           label: "Section", url_method: :facet_url_helper,
                           partial: 'custom_section_facet',
                           helper_method: :markdown_as_text_facet
    config.add_facet_field solr_name('keywords', :facetable), label: "Keyword", limit: 5, url_method: :facet_url_helper
    config.add_facet_field solr_name('creator', :facetable), label: 'Creator', limit: 5, url_method: :facet_url_helper
    config.add_facet_field solr_name('content_type', :facetable), label: "Content", show: false
    config.add_facet_field solr_name('resource_type', :facetable), label: "Format", pivot: [solr_name('resource_type', :facetable), solr_name('content_type', :facetable)], url_method: :facet_url_helper
    config.add_facet_field solr_name('search_year', :facetable), label: "Year", limit: 5, url_method: :facet_url_helper
    config.add_facet_field solr_name('exclusive_to_platform', :facetable), label: "Exclusivity", query: { exclusive_to_platform: { label: 'Exclusive to Fulcrum', fq: "#{solr_name('exclusive_to_platform', :facetable)}:yes" } }
    config.add_facet_field solr_name('contributor', :facetable), label: "Contributor", show: false
    config.add_facet_field solr_name('primary_creator_role', :facetable), label: "Creator Role", show: false
    config.add_facet_fields_to_solr_request!

    config.index.partials = %i[thumbnail index_header index]

    config.view.gallery.partials = %i[index_header index]
  end

  def facet
    super
  end

  private

    def load_presenter
      monograph_id = params[:monograph_id] || params[:id]
      raise CanCan::AccessDenied unless current_ability&.can?(:read, monograph_id)
      @monograph_presenter = Hyrax::PresenterFactory.build_for(ids: [monograph_id], presenter_class: Hyrax::MonographPresenter, presenter_args: current_ability).first
      @ebook_download_presenter = EBookDownloadPresenter.new(@monograph_presenter, current_ability, current_actor)
    end

    def add_counter_stat
      # HELIO-2292
      epub = FeaturedRepresentative.where(monograph_id: @monograph_presenter.id, kind: 'epub').first
      return if epub.blank?

      access_type = if Component.find_by(noid: epub.file_set_id)
                      "Controlled"
                    else
                      "OA_Gold"
                    end
      CounterService.from(self, @monograph_presenter).count(access_type: access_type)
    end
end
