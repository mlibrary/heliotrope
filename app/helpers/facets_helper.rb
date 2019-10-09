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

  ##
  # Determine whether a facet should be rendered as collapsed or not.
  #   - if the facet is 'active', don't collapse
  #   - if the facet is configured to collapse (the default), collapse
  #   - if the facet is configured not to collapse, don't collapse
  #
  # @param [Blacklight::Configuration::FacetField] facet_field
  # @param [Blacklight::Solr::Response::Facets::FacetField] display_facet
  # @return [Boolean]
  def should_collapse_facet?(facet_field, display_facet) # rubocop:disable  Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
    return facet_field.collapse if params[:f].blank?
    return false if facet_field_in_params?(facet_field.key)
    # NOTE: Assumes maximum pivot facet depth of 2
    display_facet.items.each do |item|
      if item.items.present?
        item.items.each do |item_item|
          next if item_item.field.blank?
          return false if facet_field_in_params?(item_item.field)
        end
      end
      next if item.field.blank?
      return false if facet_field_in_params?(item.field)
    end
    facet_field.collapse
  end

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
      content_tag(:span, class: 'facet-label') do
        link_to(path, class: 'facet_select', 'data-ga-event-action': "facet_#{facet_config.label.downcase}", 'data-ga-event-label': facet_display_value(facet_field, item)) do
          content_tag(:span, facet_display_value(facet_field, item), 'aria-label': "Add #{facet_config.label} filter: #{facet_display_value(facet_field, item)} to constrain search results to #{item.hits} #{item.hits == 1 ? 'item' : 'items'}.")
        end
      end + render_facet_count(item.hits)
    end
  end

  ##
  # Standard display of a SELECTED facet value (e.g. without a link and with a remove button)
  # @see #render_facet_value
  # @param [Blacklight::Solr::Response::Facets::FacetField] facet_field
  # @param [String] item
  def render_selected_facet_value(facet_field, item)
    facet_config = facet_configuration_for_field(facet_field)
    remove_href = search_action_path(search_state.remove_facet_params(facet_field, item))
    content_tag(:span, class: "facet-label") do
      link_to(remove_href, class: "selected remove") do
        content_tag(:span, facet_display_value(facet_field, item), 'aria-label': "Remove #{facet_config.label} filter: #{facet_display_value(facet_field, item)}.") +
          content_tag(:span, '', class: "glyphicon glyphicon-remove")
      end
    end + render_facet_count(item.hits, classes: ['selected'])
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
    classes = (options[:classes] || []) << "facet-count"
    content_tag(:span, t('blacklight.search.facets.count', number: number_with_delimiter(num)), class: classes, 'aria-hidden': true)
  end

  ##
  # Are any facet restrictions for a field in the query parameters?
  #
  # @param [[String] || [Blacklight::Configuration::FacetField]] facet_field
  # @return [Boolean]
  def facet_field_in_params?(facet_field)
    return facet_params(facet_field).present? if (facet_field.class == String) || (facet_field.class == Symbol)
    pivot = facet_field[:pivot]
    return facet_params(facet_field.field).present? if pivot.nil?
    pivot.any? { |p| facet_params(p).present? }
  end

  ##
  ## ...Blacklight Helper Override End
  ############################################################################

  ############################################################################
  ## Begin Blacklight Helper Pivot Extension...

  ##
  # Standard display of a facet pivot value in a list. Used in both _facets sidebar
  # partial and catalog/facet expanded list. Will output facet value name as
  # a link to add that to your restrictions, with count in parens.
  #
  # @param [String] facet_field
  # @param [Blacklight::Solr::Response::Facets::FacetItem] item
  # @param [Blacklight::Solr::Response::Facets::(FacetField || FacetItem)] parent
  # @param [Hash] options
  # @option options [Boolean] :suppress_link display the facet, but don't link to it
  # @return [String]
  def render_facet_pivot_value(facet_field, item, parent, options = {}) # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
    p = search_state.add_facet_params_and_redirect(facet_field, item) # Default behavior is to include parent field, but we only want the parent field if it is selected!
    if parent.class == Blacklight::Solr::Response::Facets::FacetItem
      p[:f][parent.field] = p[:f][parent.field].uniq # if parent is selected it will be included twice so force it to be unique a.k.a. singular
      p[:f][parent.field].delete(parent.value) unless facet_in_params?(parent.field, parent) # Remove parent if not selected
      p[:f].delete(parent.field) if p[:f][parent.field].empty? # Remove field if empty
      p.delete(:f) if p[:f].empty? # Remove filter if empty
    end
    facet_config = facet_configuration_for_field(facet_field)
    path = search_action_path(p)
    if options[:suppress_link]
      content_tag(:div, facet_display_value(facet_field, item), class: 'facet-label facet_select') +
          + render_facet_count(item.hits, classes: ['selected'])
    else
      content_tag(:span, class: "facet-label") do
        ga_event_action = "facet_" + facet_config.label.downcase
        ga_event_label = facet_display_value(facet_field, item)
        if item.items.blank? && parent.class == Blacklight::Solr::Response::Facets::FacetItem
          parent_config = facet_configuration_for_field(parent.field)
          ga_event_action = 'facet_' + parent_config.label.downcase + '_' + facet_config.label.downcase
          ga_event_label = facet_display_value(parent.field, parent) + '_' + facet_display_value(facet_field, item)
        end
        link_to(path, class: 'facet_select', 'data-ga-event-action': ga_event_action, 'data-ga-event-label': ga_event_label) do
          content_tag(:span, facet_display_value(facet_field, item), 'aria-label': "Add #{facet_config.label} filter: #{facet_display_value(facet_field, item)} to constrain search results to #{item.hits} #{item.hits == 1 ? 'item' : 'items'}.")
        end
      end + render_facet_count(item.hits)
    end
  end

  ##
  # Standard display of a SELECTED facet pivot value (e.g. without a link and with a remove button)
  #
  # @param [String] facet_field
  # @param [Blacklight::Solr::Response::Facets::FacetItem] item
  def render_selected_facet_pivot_value(facet_field, item, _options = {})
    # need to dup the facet values,
    # if the values aren't dup'd, then the values
    # from the session will get remove in the show view...
    p = search_state.to_hash.deep_dup
    p[:f][facet_field].delete(item.value) # Remove self from selected
    p[:f].delete(facet_field) if p[:f][facet_field].empty? # Remove field if empty
    p.delete(:f) if p[:f].empty? # Remove filter if empty
    facet_config = facet_configuration_for_field(facet_field)
    remove_href = search_action_path(p)
    content_tag(:span, class: "facet-label") do
      link_to(remove_href, class: "selected remove") do
        content_tag(:span, facet_display_value(facet_field, item), 'aria-label': "Remove #{facet_config.label} filter: #{facet_display_value(facet_field, item)}.") +
          content_tag(:span, '', class: "glyphicon glyphicon-remove")
      end
    end + render_facet_count(item.hits, classes: ["selected"])
  end

  ## ...Blacklight Helper Pivot Extension End
  ############################################################################
end
