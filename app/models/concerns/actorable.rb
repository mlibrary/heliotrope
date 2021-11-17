# frozen_string_literal: true

module Actorable
  extend ActiveSupport::Concern

  def publishers
    if Incognito.sudo_role?(self)
      [Sighrax::Publisher.from_press(Incognito.sudo_role_press(self))]
    else
      presses.map { |p| Sighrax::Publisher.from_press(p) }
    end
  end

  def publisher_role?(publisher)
    publisher_roles(publisher).any?
  end

  def publisher_roles(publisher)
    if Incognito.sudo_role?(self)
      return [] unless publishers.include?(publisher)

      [Incognito.sudo_role_press_role(self)]
    else
      roles.where(resource_type: 'Press', resource_id: publisher.press.id).map(&:role)
    end
  end

  def individual
    if Incognito.sudo_actor?(self)
      Incognito.sudo_actor_individual(self)
    else
      Greensub::Individual.find_by(email: email) if email.present?
    end
  end

  def institutions
    if Incognito.sudo_actor?(self)
      [Incognito.sudo_actor_institution(self)].compact
    else
      Services.dlps_institution.find(request_attributes)
    end
  end

  def affiliations(institution)
    if Incognito.sudo_actor?(self)
      [Incognito.sudo_actor_institution_affiliation(self)].compact.select { |ia| ia.institution_id == institution.id }
    else
      Services.dlps_institution_affiliation.find(request_attributes).select { |ia| ia.institution_id == institution.id }
    end
  end

  def products
    Greensub::Product.where(id: licenses.pluck(:product_id)).uniq
  end

  def licenses # rubocop:disable Metrics/CyclomaticComplexity
    licenses = individual&.licenses.to_a || []
    institutions.each do |institution|
      institution.licenses.each do |license|
        licenses << license if (license.license_affiliations.map(&:affiliation) & affiliations(institution).map(&:affiliation)).any?
      end
    end
    licenses.uniq
  end
end
