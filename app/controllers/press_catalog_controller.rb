# frozen_string_literal: true

class PressCatalogController < ::CatalogController
  before_action :load_press
  before_action :load_actor_product_ids
  before_action :load_allow_read_product_ids
  before_action :has_open_access
  before_action :conditional_blacklight_configuration
  before_action :wayfless_redirect_to_shib_login, only: %i[index]
  after_action :add_counter_stat, only: %i[index]

  self.theme = 'hyrax'
  with_themed_layout 'catalog'

  configure_blacklight do |config|
    config.search_builder_class = PressSearchBuilder
    config.index.partials = %i[index]
    config.view.gallery.partials = %i[index]

    config.facet_fields.tap do
      # solr facet fields not to be displayed in the index (search results) view
      config.facet_fields.delete('human_readable_type_sim')
      config.facet_fields.delete('language_sim')
      config.facet_fields.delete('press_name_ssim')
      config.facet_fields.delete('subject_sim')
      config.facet_fields.delete('creator_sim')
      config.facet_fields.delete('based_near_sim')
    end
  end

  def show_site_search?
    true
  end

  def facet
    super
  end

  # If the params specify a view, then store it in the session. If the params
  # do not specify the view, set the view parameter to the value stored in the
  # session. This enables a user with a session to do subsequent searches and have
  # them default to the last used view.
  def store_preferred_view
    session[:preferred_press_view] = params[:view] if params[:view]
  end

  private

    def load_press
      @press = Press.find_by(subdomain: params['press'])
      auth_for(Sighrax::Publisher.from_press(@press))
      return @press if @press.present?

      render file: Rails.root.join('public', '404.html'), status: :not_found, layout: false
    end

    def load_actor_product_ids
      @actor_product_ids = current_actor.products.pluck(:id)
    end

    def load_allow_read_product_ids
      @allow_read_product_ids = Sighrax.allow_read_products.pluck(:id)
    end

    def has_open_access
      @has_open_access ||=  display_works.select { |doc| doc['open_access_tesim'] == ['yes'] }.count > 0
    end

    def all_works
      children = @press.children.pluck(:subdomain)
      presses = children.push(@press.subdomain).uniq
      ActiveFedora::SolrService.query("{!terms f=press_sim}#{presses.map(&:downcase).join(',')}", rows: 100_000)
    end

    def active_works
      @active_works ||= all_works.select { |doc| doc["suppressed_bsi"] == false }
    end

    def open_works
      @open_works ||= all_works.select { |doc| doc["suppressed_bsi"] == false && doc["visibility_ssi"] == "open" }
    end

    def display_works
      if Sighrax.platform_admin?(current_actor) || Sighrax.press_admin?(current_actor, @press) || Sighrax.press_editor?(current_actor, @press)
        active_works
      else
        open_works
      end
    end

    def conditional_blacklight_configuration # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
      if @press.subdomain == Services.score_press
        musical_score
      else
        if display_works.count >= 9
          # per page
          blacklight_config.default_per_page = 15
          blacklight_config.per_page = [10, 15, 50, 100]

          # facets
          # Sort HEB facets alphabetically, others by count
          sort = (@press.subdomain == 'heb') ? 'index' : 'count'

          if Incognito.developer?(current_actor)
            # This is replaced with the Access "fake facet", HELIO-3347
            # blacklight_config.add_facet_field Solrizer.solr_name('open_access', :facetable), label: "Open Access", limit: 1, url_method: :facet_url_helper, sort: sort
            blacklight_config.add_facet_field Solrizer.solr_name('funder', :facetable), label: "Funder", limit: false, url_method: :facet_url_helper, sort: sort
            blacklight_config.add_facet_field Solrizer.solr_name('subject', :facetable), label: "Subject", limit: false, url_method: :facet_url_helper, sort: sort
            blacklight_config.add_facet_field Solrizer.solr_name('creator', :facetable), label: "Author", limit: false, url_method: :facet_url_helper, sort: sort
            if @press.subdomain == 'heb'
              blacklight_config.add_facet_field Solrizer.solr_name('publisher', :facetable), label: "Publisher", limit: false, url_method: :facet_url_helper, sort: sort
            end
            blacklight_config.add_facet_field Solrizer.solr_name('series', :facetable), label: "Series", limit: false, url_method: :facet_url_helper, sort: sort
            blacklight_config.add_facet_field Solrizer.solr_name('press_name', :facetable), label: "Source", limit: false, url_method: :facet_url_helper, sort: sort
            if Sighrax.platform_admin?(current_actor)
              blacklight_config.add_facet_field Solrizer.solr_name('product_names', :facetable), label: "Products", limit: false
            end
          else
            # This is replaced with the Access "fake facet", HELIO-3347
            # blacklight_config.add_facet_field Solrizer.solr_name('open_access', :facetable), label: "Open Access", limit: 1, url_method: :facet_url_helper, sort: sort
            blacklight_config.add_facet_field Solrizer.solr_name('funder', :facetable), label: "Funder", limit: 5, url_method: :facet_url_helper, sort: sort
            blacklight_config.add_facet_field Solrizer.solr_name('subject', :facetable), label: "Subject", limit: 10, url_method: :facet_url_helper, sort: sort
            blacklight_config.add_facet_field Solrizer.solr_name('creator', :facetable), label: "Author", limit: 5, url_method: :facet_url_helper, sort: sort
            if @press.subdomain == 'heb'
              blacklight_config.add_facet_field Solrizer.solr_name('publisher', :facetable), label: "Publisher", limit: 5, url_method: :facet_url_helper, sort: sort
            end
            blacklight_config.add_facet_field Solrizer.solr_name('series', :facetable), label: "Series", limit: 5, url_method: :facet_url_helper, sort: sort
            blacklight_config.add_facet_field Solrizer.solr_name('press_name', :facetable), label: "Source", limit: 5, url_method: :facet_url_helper, sort: sort
            if Sighrax.platform_admin?(current_actor)
              blacklight_config.add_facet_field Solrizer.solr_name('product_names', :facetable), label: "Products", limit: 5
            end
          end

          blacklight_config.add_facet_fields_to_solr_request!
        end

        blacklight_config.default_solr_params[:qf] += ' all_text_timv' if @press.subdomain == 'barpublishing'

        search_or_browse
        monograph_sort_fields
      end
    end

    def musical_score
      blacklight_config.add_facet_field Solrizer.solr_name('creator', :facetable), label: 'Composer'
      blacklight_config.add_facet_field Solrizer.solr_name('octave_compass', :facetable), label: 'Octave Compass'
      blacklight_config.add_facet_field Solrizer.solr_name('bass_bells_required', :facetable), label: 'Bass Bells Required'
      blacklight_config.add_facet_field Solrizer.solr_name('solo', :facetable), label: 'Solo'
      blacklight_config.add_facet_field Solrizer.solr_name('musical_presentation', :facetable), label: 'Musical Presentation'
      blacklight_config.add_facet_field Solrizer.solr_name('composer_diversity', :facetable), label: 'Composer Diversity'
      blacklight_config.add_facet_field Solrizer.solr_name('appropriate_occasion', :facetable), label: 'Appropriate Occasion'
    end

    def search_or_browse
      # sort fields
      if params[:q].present?
        params.extract!(:sort) if /date_uploaded/i.match?(params[:sort])
        # if this is a search, relevance/score is default
        blacklight_config.add_sort_field 'relevance', sort: "score desc, #{Solrizer.solr_name('date_uploaded', :stored_sortable, type: :date)} desc", label: "Relevance"
      else
        params.extract!(:sort) if /relevance/i.match?(params[:sort])
        # if it's a "browse", then it's date_uploaded
        blacklight_config.add_sort_field 'date_uploaded desc', sort: "#{Solrizer.solr_name('date_uploaded', :stored_sortable, type: :date)} desc", label: "Date Added (Newest First)"
      end
    end

    def monograph_sort_fields
      blacklight_config.add_sort_field 'author asc', sort: "#{Solrizer.solr_name('creator_full_name', :sortable)} asc", label: "Author (A-Z)"
      blacklight_config.add_sort_field 'author desc', sort: "#{Solrizer.solr_name('creator_full_name', :sortable)} desc", label: "Author (Z-A)"
      blacklight_config.add_sort_field 'year desc', sort: "#{Solrizer.solr_name('date_created', :sortable)} desc, #{Solrizer.solr_name('date_published', :sortable)} desc", label: "Publication Date (Newest First)"
      blacklight_config.add_sort_field 'year asc', sort: "#{Solrizer.solr_name('date_created', :sortable)} asc, #{Solrizer.solr_name('date_published', :sortable)} asc", label: "Publication Date (Oldest First)"
      blacklight_config.add_sort_field 'title asc', sort: "#{Solrizer.solr_name('title', :sortable)} asc", label: "Title (A-Z)"
      blacklight_config.add_sort_field 'title desc', sort: "#{Solrizer.solr_name('title', :sortable)} desc", label: "Title (Z-A)"
    end

    def add_counter_stat
      CounterService.for_press(self, @press).count(search: 1) if @search_ongoing
    end
end
