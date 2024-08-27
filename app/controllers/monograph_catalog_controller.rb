# frozen_string_literal: true

class MonographCatalogController < ::CatalogController
  include IrusAnalytics::Controller::AnalyticsBehaviour
  include Skylight::Helpers

  before_action :load_presenter, only: %i[index facet purchase]
  before_action :monograph_auth_for, only: %i[index purchase]
  before_action :load_press_presenter, only: %i[index purchase]
  before_action :wayfless_redirect_to_shib_login, only: %i[index]
  after_action :add_counter_stat, only: %i[index]

  self.theme = 'hyrax'
  with_themed_layout 'catalog'

  configure_blacklight do |config| # rubocop:disable Metrics/BlockLength
    config.search_builder_class = MonographSearchBuilder
    config.index.partials = %i[thumbnail index_header index]
    config.view.gallery.partials = %i[index]

    config.default_per_page = 20
    config.add_sort_field 'relevance', sort: "score desc, monograph_position_isi asc", label: "First Appearance"
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
      config.index_fields.delete('rightsholder_tesim')
      config.index_fields.delete('description_tesim')
      config.index_fields.delete('alt_text_tesim')
      config.index_fields.delete('content_type_tesim')
      config.index_fields.delete('keyword_tesim')
      config.index_fields.delete('section_title_tesim')
      config.index_fields.delete('license_tesim')
      config.index_fields.delete('date_published_dtsim')
    end

    config.add_facet_field solr_name('section_title', :facetable),
                           label: "Section", url_method: :facet_url_helper,
                           partial: 'custom_section_facet',
                           helper_method: :markdown_as_text_facet
    config.add_facet_field solr_name('keyword', :facetable), label: "Keyword", limit: 5, more_limit: 1000,
                           url_method: :facet_url_helper,
                           partial: 'case_insensitive_sort_facet'
    config.add_facet_field solr_name('creator', :facetable), label: 'Creator', limit: 5, url_method: :facet_url_helper
    config.add_facet_field solr_name('content_type', :facetable), label: "Content", show: false
    config.add_facet_field solr_name('resource_type', :facetable), label: "Format", limit: 5, url_method: :facet_url_helper
    config.add_facet_field solr_name('search_year', :facetable), label: "Year", limit: 5, url_method: :facet_url_helper
    config.add_facet_field solr_name('exclusive_to_platform', :facetable), label: "Exclusivity", query: { exclusive_to_platform: { label: 'Exclusive to Fulcrum', fq: "#{solr_name('exclusive_to_platform', :facetable)}:yes" } }
    config.add_facet_field solr_name('contributor', :facetable), label: "Contributor", show: false
    config.add_facet_field solr_name('primary_creator_role', :facetable), label: "Creator Role", show: false
    config.add_facet_fields_to_solr_request!
  end

  instrument_method
  def facet
    # Related to helpers/facets_helper#facet_url_helper
    # and views/catalog/_facet_limit.html.erb
    # For the monograph_catalog we need the monograph_id to run through blacklight
    super
  end

  instrument_method
  def show
    # this is just for skylight's instrument_method
    super
  end

  instrument_method
  def purchase
  end

  # If the params specify a view, then store it in the session. If the params
  # do not specifiy the view, set the view parameter to the value stored in the
  # session. This enables a user with a session to do subsequent searches and have
  # them default to the last used view.
  def store_preferred_view
    session[:preferred_monograph_view] = params[:view] if params[:view]
  end

  def default_url_options
    # HELIO-4332
    @except_locale = true if @monograph_presenter.present? && @monograph_presenter&.subdomain == "barpublishing"
    super
  end

  def item_identifier_for_irus_analytics
    CatalogController.blacklight_config.oai[:provider][:record_prefix] + ":" + params[:id]
  end

  private

    def valid_share_link?
      return @valid_share_link if @valid_share_link.present?

      share_link = params[:share] || session[:share_link]
      session[:share_link] = share_link

      @valid_share_link = if share_link.present?
                            begin
                              decoded = JsonWebToken.decode(share_link)
                              true if decoded[:data] == @monograph_presenter&.id
                            rescue JWT::ExpiredSignature, JWT::VerificationError
                              false
                            end
                          else
                            false
                          end
    end

    instrument_method
    def load_presenter
      retries ||= 0
      monograph_id = params[:monograph_id] || params[:id]
      @monograph_presenter = Hyrax::PresenterFactory.build_for(ids: [monograph_id], presenter_class: Hyrax::MonographPresenter, presenter_args: current_ability).first
      raise PageNotFoundError if @monograph_presenter.nil?

      # We don't "sell"/protect the Monograph catalog page. This line is the one and only place where the Monograph's...
      # draft (restricted) status can prevent it being universally seen.
      # Share links being used to "expose" the Monograph page are only for editors allowing, e.g. authors to easily...
      # review draft content. We can assume the Monograph is draft if the first condition is false.
      raise CanCan::AccessDenied unless current_ability&.can?(:read, @monograph_presenter) || valid_share_link?

    rescue RSolr::Error::ConnectionRefused, RSolr::Error::Http => e
      Rails.logger.error(%Q|[RSOLR ERROR TRY:#{retries}] #{e} #{e.backtrace.join("\n")}|)
      retries += 1
      retry if retries < 3
    end

    instrument_method
    def monograph_auth_for
      auth_for(Sighrax.from_presenter(@monograph_presenter))
      for_access_icons
      @ebook_download_presenter = EBookDownloadPresenter.new(@monograph_presenter, current_ability, current_actor)
      # The monograph catalog page is completely user-facing, apart from a small admin menu. The "Read" button should...
      # never show up if there is no published ebook for CSB to use! This is important for the "Forthcoming" workflow.
      @show_read_button = @monograph_presenter.reader_ebook? && (@monograph_presenter&.reader_ebook['visibility_ssi'] == 'open' || valid_share_link?)
      @disable_read_button = disable_read_button?
    end

    instrument_method
    def for_access_icons
      # For Access Icons HELIO-3346
      @actor_product_ids = current_actor.products.pluck(:id)
      @allow_read_product_ids = Sighrax.allow_read_products.pluck(:id)
    end

    instrument_method
    def load_press_presenter
      @press_presenter = PressPresenter.for(@monograph_presenter.subdomain)
    end

    instrument_method
    def disable_read_button?
      return true if @monograph_presenter.access_level(@actor_product_ids, @allow_read_product_ids).show? && @monograph_presenter.access_level(@actor_product_ids, @allow_read_product_ids).level == :restricted
      false
    end

    instrument_method
    def add_counter_stat
      # HELIO-2292
      return unless @monograph_presenter.epub? || @monograph_presenter.pdf_ebook? || @monograph_presenter.mobi?
      CounterService.from(self, @monograph_presenter).count
      send_irus_analytics_investigation
    end
end
