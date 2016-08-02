module FacetHelper
  def exclusivity_facet(value)
    if value == 'yes'
      "Does not appear in book"
    else
      "Appears in book"
    end
  end
end
