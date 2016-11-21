module FacetHelper
  def exclusivity_facet(value)
    if value == 'yes'
      "Does not appear in book"
    elsif value == 'no'
      "Appears in book"
    else
      "Unknown exclusivity #{value}"
    end
  end

  def facet_url_helper(facet_field, item)
    # called from the facet modal from the monograph_catalog page
    if params[:monograph_id]
      previous_params = search_state.params_for_search.except(:monograph_id, :_)['f']
      previous_param_string = ''

      if previous_params && !previous_params.empty?
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
      ordered_section_titles = monograph_presenter.section_docs.map { |s| s.title.first }
      ordered_facet_items = []
      ordered_section_titles.each do |section_title|
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
end
