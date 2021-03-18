# frozen_string_literal: true

module Greensub
  class TrialLicense < License
    def entitlements
      [:reader]
    end
  end
end
