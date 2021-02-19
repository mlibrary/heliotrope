# frozen_string_literal: true

class FullLicense < License
  def entitlements
    [:preview, :read, :download]
  end
end
