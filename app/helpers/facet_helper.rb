# frozen_string_literal: true

module FacetHelper
  include Blacklight::FacetsHelperBehavior

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
  # @return [Boolean]
  def should_collapse_facet?(facet_field)
    !facet_field_in_params?(facet_field) && facet_field.collapse
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
  def render_facet_pivot_value(facet_field, item, parent, options = {})
    p = search_state.add_facet_params_and_redirect(facet_field, item) # Default behavior is to include parent field, but we only want the parent field if it is selected!
    if parent.class == Blacklight::Solr::Response::Facets::FacetItem
      p[:f][parent.field] = p[:f][parent.field].uniq # if parent is selected it will be included twice so force it to be unique a.k.a. singular
      p[:f][parent.field].delete(parent.value) unless facet_in_params?(parent.field, parent) # Remove parent if not selected
      p[:f].delete(parent.field) if p[:f][parent.field].empty? # Remove field if empty
      p.delete(:f) if p[:f].empty? # Remove filter if empty
    end
    path = search_action_path(p)
    content_tag(:span, class: "facet-label") do
      link_to_unless(options[:suppress_link], facet_display_value(facet_field, item), path, class: "facet_select")
    end + render_facet_pivot_count(item.hits)
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
    remove_href = search_action_path(p)
    content_tag(:span, class: "facet-label") do
      content_tag(:span, facet_display_value(facet_field, item), class: "selected") +
        # remove link
        link_to(remove_href, class: "remove") do
          content_tag(:span, '', class: "glyphicon glyphicon-remove") + content_tag(:span, '[remove]', class: 'sr-only')
        end
    end + render_facet_count(item.hits, classes: ["selected"])
  end

  # Renders a count value for facet limits. Can be over-ridden locally
  # to change style. And can be called by plugins to get consistent display.
  #
  # @param [Integer] num number of facet results
  # @param [Hash] options
  # @option options [Array<String>]  an array of classes to add to count span.
  # @return [String]
  def render_facet_pivot_count(num, options = {})
    classes = (options[:classes] || []) << "facet-count"
    content_tag("span", t('blacklight.search.facets.count', number: number_with_delimiter(num)), class: classes)
  end

  ## ...Blacklight Helper Pivot Extension End
  ############################################################################
end
