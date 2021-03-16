# frozen_string_literal: true

module Greensub
  class ReadLicense < License
    def entitlements
      [:reader]
    end
  end
end
