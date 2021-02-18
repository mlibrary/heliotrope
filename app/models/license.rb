# frozen_string_literal: true

class License < ApplicationRecord
  def entitlements
    []
  end

  def allows?(action)
    entitlements.include?(action)
  end
end

class TrialLicense < License
  def entitlements
    [:preview, :reader]
  end
end

class FullLicense < License
  def entitlements
    [:preview, :reader, :download]
  end
end
