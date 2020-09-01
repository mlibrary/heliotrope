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

  ############################################################################
  ## Begin Blacklight Helper Override...

  ##
  # Determine if Blacklight should render the display_facet or not
  #
  # By default, only render facets with items.
  #
  # @param [Blacklight::Solr::Response::Facets::FacetField] display_facet
  # @return [Boolean]
  def should_render_facet?(display_facet)
    # display when show is nil or true
    facet_config = facet_configuration_for_field(display_facet.name)
    display = should_render_field?(facet_config, display_facet)
    display_facet.items.reject! { |item| item.value.blank? }
    display && display_facet.items.present? # && !display_facet.items.empty?
  end

  # I'm going to assume this override is still necessary. It looks like it was added to remove facets containing...
  # blank values, as opposed to nil which surely would not cause a problem.
  # Really we shouldn't allow anything where blank? == true to be stored in the first place.
  # Original issue: https://tools.lib.umich.edu/jira/browse/HELIO-1068

  ##
  # Standard display of a facet value in a list. Used in both _facets sidebar
  # partial and catalog/facet expanded list. Will output facet value name as
  # a link to add that to your restrictions, with count in parens.
  #
  # @param [Blacklight::Solr::Response::Facets::FacetField] facet_field
  # @param [Blacklight::Solr::Response::Facets::FacetItem] item
  # @param [Hash] options
  # @option options [Boolean] :suppress_link display the facet, but don't link to it
  # @return [String]
  def render_facet_value(facet_field, item, options = {})
    facet_config = facet_configuration_for_field(facet_field)
    path = path_for_facet(facet_field, item)
    if options[:suppress_link]
      content_tag(:span, facet_display_value(facet_field, item), class: 'facet-label') +
        render_facet_count(item.hits)
    else
      link_to(path, class: 'facet-anchor facet_select', 'data-ga-event-action': "facet_#{facet_config.label.downcase}", 'data-ga-event-label': facet_display_value(facet_field, item), 'aria-label': "#{facet_display_value(facet_field, item)} filter #{item.hits}") do
        content_tag(:span, facet_display_value(facet_field, item), class: 'facet-label') +
          render_facet_count(item.hits)
      end
    end
  end

  ##
  # Standard display of a SELECTED facet value (e.g. without a link and with a remove button)
  # @see #render_facet_value
  # @param [Blacklight::Solr::Response::Facets::FacetField] facet_field
  # @param [String] item
  def render_selected_facet_value(facet_field, item)
    remove_href = search_action_path(search_state.remove_facet_params(facet_field, item))
    link_to(remove_href, class: 'facet-anchor selected remove', 'aria-label': "Remove #{facet_display_value(facet_field, item)} filter") do
      content_tag(:span, facet_display_value(facet_field, item), class: 'facet-label') +
        content_tag(:span, '', class: 'glyphicon glyphicon-remove')
    end
  end

  ##
  # Renders a count value for facet limits. Can be over-ridden locally
  # to change style. And can be called by plugins to get consistent display.
  #
  # @param [Integer] num number of facet results
  # @param [Hash] options
  # @option options [Array<String>]  an array of classes to add to count span.
  # @return [String]
  def render_facet_count(num, options = {})
    content_tag(:span, t('blacklight.search.facets.count', number: number_with_delimiter(num)))
  end

  ##
  ## ...Blacklight Helper Override End
  ############################################################################
end
