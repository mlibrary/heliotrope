# frozen_string_literal: true

class Auth
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

  def actor_platform_admin?
    @actor.platform_admin?
  end

  def actor_publisher_role?
    @actor.publisher_role?(@publisher)
  end

  def actor_publisher_roles
    @actor.publisher_roles(@publisher)
  end

  def actor_sudo_actor?
    Incognito.sudo_actor?(@actor)
  end

  def actor_sudo_role?
    Incognito.sudo_role?(@actor)
  end

  def actor_sudo_platform_admin?
    Incognito.allow_platform_admin?(@actor)
  end

  def actor_sudo_developer?
    Incognito.developer?(@actor)
  end

  def actor_authorized?
    return true unless @monograph.restricted?

    return true if @monograph.open_access?

    EPubPolicy.new(@actor, @monograph.ebook, false).show?
  end

  def actor_unauthorized?
    !actor_authorized?
  end

  def actor_authenticated?
    @actor.institutions.present?
  end

  def actor_single_sign_on_authenticated?
    entity_id = @actor.request_attributes[:identity_provider]
    entity_id.present? || Incognito.developer?(@actor)
  end

  def actor_subscribing_institutions
    return @actor_subscribing_institutions unless @actor_subscribing_institutions.nil?

    @actor_subscribing_institutions = @actor.institutions & monograph_subscribing_institutions
    @actor_subscribing_institutions = @actor.institutions & publisher_subscribing_institutions if @actor_subscribing_institutions.empty?
    @actor_subscribing_institutions
  end

  def publisher?
    @publisher.valid?
  end

  def publisher_subdomain
    @publisher.subdomain
  end

  def publisher_name
    @publisher.name
  end

  def publisher_restricted_content?
    @publisher_restricted_content ||= Greensub::Component.where(noid: @publisher.work_noids(true)).any?
  end

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

  def publisher_subscribing_institutions
    return @publisher_subscribing_institutions unless @publisher_subscribing_institutions.nil?

    return @publisher_subscribing_institutions = [] unless @publisher.valid?

    @publisher_subscribing_institutions = subscribing_institutions(@publisher.work_noids(true))
  end

  def monograph?
    @monograph.valid?
  end

  def monograph_id
    @monograph.noid
  end

  def monograph_buy_url?
    monograph_buy_url.present?
  end

  def monograph_buy_url
    @monograph.buy_url
  end

  def monograph_worldcat_url?
    monograph_worldcat_url.present?
  end

  def monograph_worldcat_url
    @monograph.worldcat_url
  end

  def monograph_isbn?
    @monograph.preferred_isbn.present?
  end

  def monograph_isbn
    @monograph.preferred_isbn
  end

  def monograph_subscribing_institutions
    return @monograph_subscribing_institutions unless @monograph_subscribing_institutions.nil?

    return @monograph_subscribing_institutions = [] unless @monograph.valid?

    @monograph_subscribing_institutions = subscribing_institutions(@monograph.noid)
  end

  def resource?
    @resource.valid?
  end

  def resource_id
    @resource.noid
  end

  def institution?
    institution.present?
  end

  def institution
    @institution ||= actor_subscribing_institutions.first || @actor.institutions.first
  end

  private

    def subscribing_institutions(noids)
      component_ids = Greensub::Component.where(noid: noids).pluck(:id).uniq
      product_ids = Greensub::ComponentsProduct.where(component_id: component_ids).pluck(:product_id).uniq
      institution_ids = Greensub::License.where(product_id: product_ids, licensee_type: Greensub::Institution.to_s).pluck(:licensee_id).uniq
      Greensub::Institution.where(id: institution_ids).to_a
    end
end
