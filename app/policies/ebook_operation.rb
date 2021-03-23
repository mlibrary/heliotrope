# frozen_string_literal: true

class EbookOperation < ApplicationPolicy
  protected

    alias_attribute :ebook, :target

    def licensed_for?(entitlement)
      authority
        .licenses_for(actor, ebook)
        .any? { |license| license.allows?(entitlement) }
    end
end
