# frozen_string_literal: true

class EbookOperation < ApplicationPolicy
  include AbilityHelpers

  protected

    alias_attribute :ebook, :target

    def accessible_online?
      ebook.published? && !ebook.tombstone?
    end

    def accessible_offline?
      ebook.allow_download? && accessible_online?
    end

    def unrestricted?
      ebook.open_access? || !ebook.restricted?
    end

    def licensed_for?(entitlement)
      authority
        .licenses_for(actor, ebook)
        .any? { |license| license.allows?(entitlement) }
    end
end
