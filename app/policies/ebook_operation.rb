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
      if Incognito.developer?(actor) # TODO: remove
        licenses = authority.licenses_for(actor, ebook)

        return true if licenses
                        .where(licensee_type: "Greensub::Individual")
                        .any? { |license| license.allows?(entitlement) }

        return true if licenses
                        .where(licensee_type: "Greensub::Institution")
                        .any? { |license| license.allows?(entitlement) && (license.affiliations.map(&:affiliation) & actor.affiliations(license.licensee).map(&:affiliation)).any? }

        world_institution_ids = Greensub::Institution.where(identifier: Settings.world_institution_identifier).pluck(:id).to_a
        return true if licenses
                         .where(licensee_type: "Greensub::Institution", licensee_id: world_institution_ids)
                         .any? { |license| license.allows?(entitlement) }

        false
      else
        authority
          .licenses_for(actor, ebook)
          .to_a
          .any? { |license| license.allows?(entitlement) }
      end
    end
end
