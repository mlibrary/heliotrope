module FacetHelper
  def exclusivity_facet(value)
    if value == 'yes'
      "Does not appear in book"
    else
      "Appears in book"
    end
  end

  def facet_url_helper(facet_field, item)
    if params[:monograph_id]
      # called from the facet modal from the monograph_catalog page
      "#{params[:monograph_id]}?f%5B#{facet_field}%5D%5B%5D=#{item.value}"
    else
      search_action_path(search_state.add_facet_params_and_redirect(facet_field, item))
    end
  end
end
