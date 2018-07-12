# frozen_string_literal: true

class PressCatalogController < ::CatalogController
  before_action :load_press

  self.theme = 'curation_concerns'
  with_themed_layout 'catalog'

  configure_blacklight do |config|
    config.search_builder_class = PressSearchBuilder
    config.index.partials = %i[thumbnail index_header]
    config.view.gallery.partials = %i[index_header index]

    config.default_per_page = 15
    config.per_page = [10, 15, 50, 100]

    config.add_sort_field 'relevance', sort: "score desc, #{solr_name('date_uploaded', :stored_sortable, type: :date)} desc", label: "Relevance"
    config.add_sort_field 'author asc', sort: "#{solr_name('creator_full_name', :sortable)} asc", label: "Author (A-Z)"
    config.add_sort_field 'author desc', sort: "#{solr_name('creator_full_name', :sortable)} desc", label: "Author (Z-A)"
    config.add_sort_field 'year desc', sort: "#{solr_name('date_created', :sortable)} desc", label: "Publication Date (Newest First)"
    config.add_sort_field 'year asc', sort: "#{solr_name('date_created', :sortable)} asc", label: "Publication Date (Oldest First)"
    config.add_sort_field 'title asc', sort: "#{Solrizer.solr_name('title', :sortable)} asc", label: "Title (A-Z)"
    config.add_sort_field 'title desc', sort: "#{Solrizer.solr_name('title', :sortable)} desc", label: "Title (Z-A)"

    config.facet_fields.tap do
      # solr facet fields not to be displayed in the index (search results) view
      config.facet_fields.delete('human_readable_type_sim')
      config.facet_fields.delete('language_sim')
      config.facet_fields.delete('press_name_ssim')
      config.facet_fields.delete('subject_sim')
      config.facet_fields.delete('creator_full_name_sim')
      config.facet_fields.delete('based_near_sim')
    end

    config.add_facet_field solr_name('subject', :facetable), label: "Subject", limit: 10, url_method: :facet_url_helper
    config.add_facet_field solr_name('creator_full_name', :facetable), label: "Author", limit: 5, url_method: :facet_url_helper
    config.add_facet_field solr_name('publisher', :facetable), label: "Publisher", limit: 5, url_method: :facet_url_helper
    config.add_facet_field solr_name('series', :facetable), label: "Series", limit: 5, url_method: :facet_url_helper
    config.add_facet_fields_to_solr_request!

    config.index.partials = %i[thumbnail index_header]
    config.view.gallery.partials = %i[index_header index]
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
