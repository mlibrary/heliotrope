# frozen_string_literal: true

module Greensub
  class FullLicense < License
    def entitlements
      [:download, :reader]
    end
  end
end
