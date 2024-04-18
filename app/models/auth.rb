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
    @actor_authorized ||= if !@monograph.restricted? || @monograph.open_access?
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
  def publisher_work_noids
    @publisher_work_noids ||= @publisher.work_noids(true)
  end

  instrument_method
  def publisher_restricted_content?
    @publisher_restricted_content ||= Greensub::Component.where(noid: publisher_work_noids).any? &&
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

    @publisher_subscribing_institutions = subscribing_institutions(publisher_work_noids)
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

    @monograph_subscribing_institutions = subscribing_institutions(@monograph.noid)
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

    instrument_method
    def subscribing_institutions(noids)
      component_ids = Greensub::Component.where(noid: noids).pluck(:id).uniq
      product_ids = Greensub::ComponentsProduct.where(component_id: component_ids).pluck(:product_id).uniq
      institution_ids = Greensub::License.where(product_id: product_ids, licensee_type: Greensub::Institution.to_s).pluck(:licensee_id).uniq
      Greensub::Institution.where(id: institution_ids).to_a
    end
end
