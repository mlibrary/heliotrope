# frozen_string_literal: true

class Auth
  include Skylight::Helpers

  instrument_method
  def initialize(actor, entity)
    @actor = actor
    @entity = entity
    @publisher = Sighrax::Publisher.null_publisher
    @monograph = Sighrax::Monograph.null_entity
    @resource = Sighrax::Resource.null_entity
    case @entity
    when Sighrax::Publisher
      @publisher = @entity
    when Sighrax::Monograph
      @monograph = @entity
      @publisher = @monograph.publisher
    when Sighrax::Resource
      @resource = @entity
      @monograph = @resource.parent
      @publisher = @monograph.publisher
    end
    # Force evaluation of lazy methods
    publisher_restricted_content?
    publisher_subscribing_institutions
    monograph_subscribing_institutions
    actor_subscribing_institutions
  end

  def return_location
    case @entity
    when Sighrax::Publisher
      Rails.application.routes.url_helpers.press_catalog_path(publisher_subdomain)
    when Sighrax::Monograph
      Rails.application.routes.url_helpers.monograph_catalog_path(@monograph.noid)
    when Sighrax::Resource
      Rails.application.routes.url_helpers.hyrax_file_set_path(@resource.noid)
    end
  end

  instrument_method
  def actor_authorized?
    return @actor_authorized if defined? @actor_authorized

    @actor_authorized = if !@monograph.restricted? || @monograph.open_access?
                          true
                        else
                          EPubPolicy.new(@actor, @monograph.ebook, false).show?
                        end
  end

  instrument_method
  def actor_unauthorized?
    !actor_authorized?
  end

  instrument_method
  def actor_authenticated?
    @actor.institutions.present?
  end

  instrument_method
  def actor_single_sign_on_authenticated?
    entity_id = @actor.request_attributes[:identity_provider]
    entity_id.present? || Incognito.developer?(@actor)
  end

  instrument_method
  def actor_subscribing_institutions
    return @actor_subscribing_institutions unless @actor_subscribing_institutions.nil?

    @actor_subscribing_institutions = @actor.institutions & monograph_subscribing_institutions
    @actor_subscribing_institutions = @actor.institutions & publisher_subscribing_institutions if @actor_subscribing_institutions.empty?
    @actor_subscribing_institutions
  end

  instrument_method
  def publisher?
    @publisher.valid?
  end

  instrument_method
  def publisher_subdomain
    @publisher.subdomain
  end

  instrument_method
  def publisher_name
    @publisher.name
  end

  instrument_method
  def product_ids_from_press
    return @product_ids_from_press if @product_ids_from_press.present?

    # Use facets to get unique product ids for all monographs in a press
    solr_params = {
      'facet.field' => 'products_lsim',
      'facet' => 'on',
      'facet.limit' => '-1', # no limit
      'rows' => 0 # don't return any actual solr docs
    }

    # Include children presses
    subdomains = @publisher.children.map(&:subdomain) || []
    subdomains.push(@publisher.subdomain)
    all_presses = '("' + subdomains.join('" OR "') + '")'

    response = ActiveFedora::SolrService.get("+press_sim:#{all_presses} +has_model_ssim:Monograph", solr_params)
    #
    # response["facet_counts"]["facet_fields"]["products_lsim"] has key/values in an array like:
    # ["24", 1570, "22", 597, "-1", 381, "90", 316, "0", 173...]
    # It also includes product_lsim that have 0 values.
    # Facets basically get all the products even if no books from this press are in that product.
    #
    # We don't need those "empty" products.
    # We don't need the "-1" Open Access product because all OA books will have -1 which is not helpful for this
    # We don't need "0" No Product product since those don't have components, it's just a placeholder product
    #
    products_lsim = response["facet_counts"]["facet_fields"]["products_lsim"]
    @products_ids_from_press = products_lsim.each_slice(2).filter_map { |k, v| k if v != 0 && k != "-1" && k != "0" }.compact
  end

  instrument_method
  def components_in_press?
    @components_in_press ||= Greensub::ComponentsProduct.where(product_id: product_ids_from_press).present?
  end

  instrument_method
  def publisher_restricted_content?
    @publisher_restricted_content ||= components_in_press? &&
                                      (publisher_subscribing_institutions - Greensub::Institution.where(identifier: Settings.world_institution_identifier)).present?
  end

  instrument_method
  def publisher_individual_subscribers?
    case publisher_subdomain
    when 'heliotrope'
      Incognito.developer?(@actor)
    when 'heb'
      true
    else
      false
    end
  end

  instrument_method
  def publisher_subscribing_institutions
    return @publisher_subscribing_institutions unless @publisher_subscribing_institutions.nil?

    return @publisher_subscribing_institutions = [] unless @publisher.valid?

    @publisher_subscribing_institutions = subscribing_institutions_from_product_ids(product_ids_from_press)
  end

  instrument_method
  def monograph?
    @monograph.valid?
  end

  instrument_method
  def monograph_id
    @monograph.noid
  end

  instrument_method
  def monograph_buy_url?
    monograph_buy_url.present?
  end

  instrument_method
  def monograph_buy_url
    @monograph.buy_url
  end

  instrument_method
  def monograph_worldcat_url?
    monograph_worldcat_url.present?
  end

  instrument_method
  def monograph_worldcat_url
    @monograph.worldcat_url
  end

  instrument_method
  def monograph_isbn?
    @monograph.preferred_isbn.present?
  end

  instrument_method
  def monograph_isbn
    @monograph.preferred_isbn
  end

  instrument_method
  def monograph_subscribing_institutions
    return @monograph_subscribing_institutions unless @monograph_subscribing_institutions.nil?
    return @monograph_subscribing_institutions = [] unless @monograph.valid?

    @monograph_subscribing_institutions = subscribing_institutions_from_product_ids(@monograph.product_ids)
  end

  instrument_method
  def resource?
    @resource.valid?
  end

  instrument_method
  def resource_id
    @resource.noid
  end

  instrument_method
  def institution?
    institution.present?
  end

  instrument_method
  def institution
    @institution ||= actor_subscribing_institutions.first || @actor.institutions.first
  end

  private

    def subscribing_institutions_from_product_ids(product_ids)
      institution_ids = Greensub::License.where(product_id: product_ids, licensee_type: Greensub::Institution.to_s).pluck(:licensee_id).uniq
      Greensub::Institution.where(id: institution_ids).to_a
    end
end
