# frozen_string_literal: true

class PressCatalogController < ::CatalogController
  before_action :load_press
  before_action :conditional_blacklight_configuration

  self.theme = 'curation_concerns'
  with_themed_layout 'catalog'

  configure_blacklight do |config|
    config.search_builder_class = PressSearchBuilder
    config.index.partials = %i[thumbnail index_header]
    config.view.gallery.partials = %i[index_header index]

    config.facet_fields.tap do
      # solr facet fields not to be displayed in the index (search results) view
      config.facet_fields.delete('human_readable_type_sim')
      config.facet_fields.delete('language_sim')
      config.facet_fields.delete('press_name_ssim')
      config.facet_fields.delete('subject_sim')
      config.facet_fields.delete('creator_sim')
      config.facet_fields.delete('based_near_sim')
    end

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

    def open_monographs
      children = @press.children.pluck(:subdomain)
      presses = children.push(@press.subdomain).uniq
      docs = ActiveFedora::SolrService.query("{!terms f=press_sim}#{presses.map(&:downcase).join(',')}", rows: 100_000)
      docs.select { |doc| doc["suppressed_bsi"] == false && doc["visibility_ssi"] == "open" }.count
    end

    def conditional_blacklight_configuration
      if open_monographs >= 15
        # per page
        blacklight_config.default_per_page = 15
        blacklight_config.per_page = [10, 15, 50, 100]

        # facets
        # Sort HEB facets alphabetically, others by count
        sort = (@press.subdomain == 'heb') ? 'index' : 'count'
        blacklight_config.add_facet_field Solrizer.solr_name('open_access', :facetable), label: "Open Access", limit: 1, url_method: :facet_url_helper, sort: sort
        blacklight_config.add_facet_field Solrizer.solr_name('subject', :facetable), label: "Subject", limit: 10, url_method: :facet_url_helper, sort: sort
        blacklight_config.add_facet_field Solrizer.solr_name('creator', :facetable), label: "Author", limit: 5, url_method: :facet_url_helper, sort: sort
        if @press.subdomain == 'heb'
          blacklight_config.add_facet_field Solrizer.solr_name('publisher', :facetable), label: "Publisher", limit: 5, url_method: :facet_url_helper, sort: sort
        end
        blacklight_config.add_facet_field Solrizer.solr_name('series', :facetable), label: "Series", limit: 5, url_method: :facet_url_helper, sort: sort
        blacklight_config.add_facet_fields_to_solr_request!
      end

      # sort fields
      if params[:q].present?
        # if this is a search, relevance/score is default
        blacklight_config.add_sort_field 'relevance', sort: "score desc, #{Solrizer.solr_name('date_uploaded', :stored_sortable, type: :date)} desc", label: "Relevance"
      else
        # if it's a "browse", then it's date_uploaded
        blacklight_config.add_sort_field 'date_uploaded desc', sort: "#{Solrizer.solr_name('date_uploaded', :stored_sortable, type: :date)} desc", label: "Date Added (Newest First)"
      end
      blacklight_config.add_sort_field 'author asc', sort: "#{Solrizer.solr_name('creator_full_name', :sortable)} asc", label: "Author (A-Z)"
      blacklight_config.add_sort_field 'author desc', sort: "#{Solrizer.solr_name('creator_full_name', :sortable)} desc", label: "Author (Z-A)"
      blacklight_config.add_sort_field 'year desc', sort: "#{Solrizer.solr_name('date_created', :sortable)} desc", label: "Publication Date (Newest First)"
      blacklight_config.add_sort_field 'year asc', sort: "#{Solrizer.solr_name('date_created', :sortable)} asc", label: "Publication Date (Oldest First)"
      blacklight_config.add_sort_field 'title asc', sort: "#{Solrizer.solr_name('title', :sortable)} asc", label: "Title (A-Z)"
      blacklight_config.add_sort_field 'title desc', sort: "#{Solrizer.solr_name('title', :sortable)} desc", label: "Title (Z-A)"
    end
end
