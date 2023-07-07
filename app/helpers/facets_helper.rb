# frozen_string_literal: true

module FacetsHelper # rubocop:disable Metrics/ModuleLength
  include Blacklight::FacetsHelperBehavior

  def facet_pagination_sort_index_label(facet_field)
    case facet_field.key
    when 'search_year_sim'
      'By Year'
    else
      t('blacklight.search.facets.sort.index')
    end
  end

  def facet_pagination_sort_count_label(facet_field)
    case facet_field.key
    when 'search_year_sim'
      'Number of Items Available'
    else
      t('blacklight.search.facets.sort.count')
    end
  end

  def facet_url_helper(facet_field, item)
    # called from the facet modal from the monograph_catalog page
    if params[:monograph_id]
      previous_params = search_state.params_for_search.except(:monograph_id, :_)['f']
      previous_param_string = ''

      if previous_params.present?
        previous_params.each do |facet, values|
          values.each do |value|
            previous_param_string += "&f%5B#{facet}%5D%5B%5D=#{value}"
          end
        end
      end
      "#{params[:monograph_id]}?f%5B#{facet_field}%5D%5B%5D=#{item.value}#{previous_param_string}"
    else
      search_action_path(search_state.add_facet_params_and_redirect(facet_field, item))
    end
  end

  def reorder_section_facet(monograph_presenter, paginator)
    # if on the dedicated facet page, defer to the user's sort choice
    if !params['facet.sort']
      ordered_facet_items = []
      monograph_presenter.ordered_section_titles.each do |section_title|
        paginator.items.each do |item|
          next unless item.value == section_title
          ordered_facet_items << Blacklight::Solr::Response::Facets::FacetItem.new(label: render_markdown(item.value),
                                                                                   value: item.value,
                                                                                   hits: item.hits)
        end
      end
      # if a limit is desired it can be added as a second parameter here, but for now I think all sections should display
      Blacklight::Solr::FacetPaginator.new(ordered_facet_items)
    else
      paginator
    end
  end

  # https://tools.lib.umich.edu/jira/browse/HELIO-3111
  # possibly this should be used sparingly or else we'll have a lot on in-line sorting/processing of the type...
  # that would best be handled by cached DB queries
  def case_insensitive_sort_facet(paginator)
    # if on the dedicated facet page, defer to the user's sort choice
    sorted_items = if paginator.sort == 'index'
                     paginator.items.sort_by { |item| item.value.downcase }
                   else # i.e. paginator.sort == 'count', fall back on the case-insensitive alpha sort
                     # https://stackoverflow.com/a/16628808 for ASC/DESC trick
                     paginator.items.sort { |a, b| [b.hits, a.value.downcase] <=> [a.hits, b.value.downcase] }
                   end
    Blacklight::Solr::FacetPaginator.new(sorted_items)
  end

  def markdown_as_text_facet(value)
    render_markdown_as_text(value)
  end
end
