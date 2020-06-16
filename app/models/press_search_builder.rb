# frozen_string_literal: true

class PressSearchBuilder < ::SearchBuilder
  self.default_processor_chain += [
      :filter_by_press,
      :show_works_or_works_that_contain_files
  ]

  def filter_by_press(solr_parameters)
    solr_parameters[:fq] ||= []
    children = Press.find_by(subdomain: blacklight_params['press']).children.pluck(:subdomain)
    all_presses = children.push(blacklight_params['press']).uniq
    solr_parameters[:fq] << "{!terms f=press_sim}#{all_presses.map(&:downcase).join(',')}"
  end

  # show both works that match the query and works that contain files that match the query
  # see https://github.com/samvera/hyrax/blob/1477059ba7983bc3e1e3980d107d3ebc1b1f4af4/app/search_builders/hyrax/catalog_search_builder.rb#L10
  def show_works_or_works_that_contain_files(solr_parameters)
    return if blacklight_params[:q].blank? || blacklight_params['press'] != 'barpublishing'
    solr_parameters[:user_query] = blacklight_params[:q]
    solr_parameters[:q] = new_query
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
end
