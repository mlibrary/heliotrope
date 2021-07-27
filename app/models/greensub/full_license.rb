# frozen_string_literal: true

module Greensub
  class FullLicense < License
    belongs_to :licensee, polymorphic: true

    def entitlements
      [:download, :reader]
    end
  end
end
