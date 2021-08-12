# frozen_string_literal: true

module Greensub
  class ReadLicense < License
    belongs_to :licensee, polymorphic: true

    def entitlements
      [:reader]
    end
  end
end
