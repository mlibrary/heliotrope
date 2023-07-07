# frozen_string_literal: true

class UserAccessFacetComponent < Blacklight::Component
  include Blacklight::ContentAreasShim

  # In the press_catalog this facet is "open_access_sim" but we actually don't care about that, it's just
  # needed to keep blacklight happy.
  # Instead this "fake" facet will have radio buttons that users can use to filter works they have
  # access to, see HELIO-3347, HELIO-4517

  def initialize(facet_field:, layout: nil)
    @facet_field = facet_field
    @layout = Blacklight::FacetFieldNoLayoutComponent
  end
end
