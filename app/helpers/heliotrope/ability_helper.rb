# frozen_string_literal: true

# This was in CurationConcerns but is not in Hyrax. Heliotrope needs it right now
# though specifically for views/shared/_add_content.html.erb. If we decide to
# make the views more like hyrax and less like CC, this can probably go away
module Heliotrope
  module AbilityHelper
    # Returns true if can create at least one type of work
    def can_ever_create_works?
      can = false
      Hyrax.config.curation_concerns.each do |curation_concern_type|
        break if can
        can = can?(:create, curation_concern_type)
      end
      can
    end
  end
end
