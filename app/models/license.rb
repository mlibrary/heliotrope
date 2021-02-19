# frozen_string_literal: true

class License < ApplicationRecord
  def entitlements
    []
  end

  def allows?(action)
    entitlements.include?(action)
  end
end
