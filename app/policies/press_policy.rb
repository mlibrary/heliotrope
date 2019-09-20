# frozen_string_literal: true

class PressPolicy < ApplicationPolicy
  alias_attribute :press, :target

  def interval_read_button?(interval)
    interval.downloadable?
  end

  def interval_download_button?(interval)
    return false unless interval.downloadable?
    interval_download?
  end

  def interval_download?
    return true if actor_platform_admin?
    /^heb$/.match?(press.subdomain) || /^heliotrope$/.match?(press.subdomain)
  end

  def watermark_download?
    press.watermark
  end

  private
    def actor_platform_admin?
      @actor_platform_admin ||= Sighrax.platform_admin?(actor)
    end
end
