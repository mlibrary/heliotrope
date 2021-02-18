# frozen_string_literal: true

class PdfPolicy < ResourcePolicy
  # You can download this PDF from the reader interface if:
  # 1. You or your institution have a full license for any product containing it, or
  # 2. You are an admin or editor for the press publishing this monograph, or
  # 3. You are a platform admin
  # Trial licenses do not qualify for PDF downloads
  def show?
    licensed = authority
      .licenses_for(actor, target)
      .any? {|license| license.allows?(:download) }

    licensed || editor_or_stronger?
  end

  def editor_or_stronger?
    # These methods should transform into authority questions
    press = target._press
    Sighrax.platform_admin?(actor)
      || Sighrax.press_admin?(actor, press)
      || Sighrax.press_editor?(actor, press)
  end
end
