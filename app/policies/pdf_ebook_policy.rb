# frozen_string_literal: true

class PdfEbookPolicy < ResourcePolicy
  def show?
    true
  end

  # You can download this PDF from the reader interface if:
  # 1. You or your institution have a full license for any product containing it, or
  # 2. You are an admin or editor for the press publishing this monograph, or
  # 3. You are a platform admin
  # Trial licenses do not qualify for PDF downloads
  def download?
    return true if editor?

    return false unless accessible?

    unrestricted? || licensed_for?(:download)
  end

  private

    def editor?
      # These methods should transform into authority questions
      press = target._press
      Sighrax.platform_admin?(actor) ||
        Sighrax.press_admin?(actor, press) ||
        Sighrax.press_editor?(actor, press)
    end

    def accessible?
      target.allow_download? && target.published? && !target.tombstone?
    end

    def unrestricted?
      target.open_access? || !target.restricted?
    end

    def licensed_for?(entitlement)
      authority
        .licenses_for(actor, target)
        .any? { |license| license.allows?(entitlement) }
    end
end
