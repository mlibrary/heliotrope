# frozen_string_literal: true

class TrialLicense < License
  def entitlements
    [:preview, :read]
  end
end
