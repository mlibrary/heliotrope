# frozen_string_literal: true

class EbookOperation < ApplicationPolicy
  protected

    def licensed_for?(entitlement)
      authority
        .licenses_for(actor, target)
        .any? { |license| license.allows?(entitlement) }
    end
end
