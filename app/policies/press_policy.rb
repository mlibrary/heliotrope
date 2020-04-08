# frozen_string_literal: true

class PressPolicy < ApplicationPolicy
  alias_attribute :press, :target

  def allows_interval_download?
    ['barpublishing', 'heb', 'heliotrope'].include? press.subdomain
  end

  def watermark_download?
    press.watermark
  end
end
