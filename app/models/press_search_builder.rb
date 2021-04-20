# frozen_string_literal: true

class PressSearchBuilder < ::SearchBuilder
  self.default_processor_chain += [
      :filter_by_press,
      :filter_by_product_access,
      :show_works_or_works_that_contain_files,
      :filter_out_tombstones
  ]

  def filter_by_press(solr_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << "{!terms f=press_sim}#{all_presses.map(&:downcase).join(',')}"
  end

  def url_press
    @url_press ||= Press.find_by(subdomain: blacklight_params['press'])
  end

  def all_presses
    @all_presses ||= url_press.children.pluck(:subdomain).push(url_press.subdomain).uniq
  end

  def filter_by_product_access(solr_parameters)
    # TODO: Not sure if we should have an admin over ride. Decide if we want this or not.
    # return if press_admin_role_override?

    # these URL params can be set by radio buttons in the UI "facet looking thing" seen in the wireframes
    if blacklight_params['user_access'] == 'true'
      solr_parameters[:fq] ||= []
      solr_parameters[:fq] << "{!terms f=products_lsim}#{all_product_ids_accessible_by_current_actor.join(',')}"
    elsif blacklight_params['user_access'] == 'oa'
      solr_parameters[:fq] ||= []
      solr_parameters[:fq] << "{!terms f=products_lsim}-1" # equivalent to solr_parameters[:fq] << "+open_access_tesim:yes"
    end
  end

  # show both works that match the query and works that contain files that match the query
  # see https://github.com/samvera/hyrax/blob/1477059ba7983bc3e1e3980d107d3ebc1b1f4af4/app/search_builders/hyrax/catalog_search_builder.rb#L10
  def show_works_or_works_that_contain_files(solr_parameters)
    return if blacklight_params[:q].blank? || blacklight_params['press'] != 'barpublishing'
    solr_parameters[:user_query] = blacklight_params[:q]
    solr_parameters[:q] = new_query
  end

  def filter_out_tombstones(solr_parameters)
    return if press_admin_role_override?

    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << "-tombstone_ssim:[* TO *]"
  end

  def default_sort_field
    # This code is working at the moment (see HELIO-3429).
    # default_sort_field is a very ubiquitous term and is defined multiple times in multiple locations
    # blacklight_config.default_sort_field appears to morph between being a hash and being a method
    # In short this is a hack because I have no idea why it works.
    # Feel free to purge this code and find a better solution.
    case blacklight_params['press']
    when /^barpublishing$/i
      if blacklight_params['q'].present?
        blacklight_config.default_sort_field
      else
        blacklight_config.sort_fields['year desc'] # Sort by Publication Date (Newest First)
      end
    else
      blacklight_config.default_sort_field
    end
  end

  private

    # the {!lucene} gives us the OR syntax
    def new_query
      "{!lucene}#{interal_query(dismax_query)} #{interal_query(join_for_works_from_files)}"
    end

    # the _query_ allows for another parser (aka dismax)
    def interal_query(query_value)
      "_query_:\"#{query_value}\""
    end

    # the {!dismax} causes the query to go against the query fields
    def dismax_query
      "{!dismax v=$user_query}"
    end

    # join from file id to work relationship solrized file_set_ids_ssim
    def join_for_works_from_files
      "{!join from=#{ActiveFedora.id_field} to=file_set_ids_ssim}#{dismax_query}"
    end

    def press_admin_role_override?
      return true if current_user&.platform_admin?
      admin_roles = Role.where(user: current_user, resource_type: 'Press', resource_id: url_press.id, role: ['admin', 'editor']).map(&:role) & ['admin', 'editor']
      admin_roles.present?
    end

    def all_product_ids_accessible_by_current_actor
      # HELIO-3347 Indicate access levels on Publisher page
      #
      # -1 == Imaginary product ID for Open Access monographs.
      #  0 == Default product ID for all non-product Monographs a.k.a. Monographs that are not components.
      #  allow_read_products == free to read products
      #  actor_products == current actor's products
      #
      allow_read_products_ids = Sighrax.allow_read_products.pluck(:id)
      actor_products_ids = Sighrax.actor_products(scope.current_actor).pluck(:id)
      ([-1, 0] + allow_read_products_ids + actor_products_ids).uniq.sort
    end
end
